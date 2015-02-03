Config = require "./config"
zmq = require "zmq"
fs = require "fs"
Proto = require "virtdb-proto"
FieldData = require "./fieldData"
Const = (require "virtdb-connector").Constants
util = require "util"
moment = require "moment"
log = (require "virtdb-connector").log
V_ = log.Variable

DiagProto = Proto.diag

class DiagConnector

    @_records: null
    @_logRecordSocket: null

    @MAX_STORED_MESSAGE_COUNT = 2000
    @LEVELS: null

    @connect: (diagServiceName) =>
        try
            @LEVELS = ["VIRTDB_STATUS", "VIRTDB_ERROR", "VIRTDB_INFO"]
            if Config.getCommandLineParameter("trace") is true then @LEVELS.push "VIRTDB_SIMPLE_TRACE"
            addresses = EndpointService.getInstance().getComponentAddresses diagServiceName
            logRecordAddress = addresses[Const.ENDPOINT_TYPE.LOG_RECORD][Const.SOCKET_TYPE.PUB_SUB][0]
            @_logRecordSocket = zmq.socket(Const.ZMQ_SUB)
            @_logRecordSocket.on "message", @_onRecord
            @_logRecordSocket.connect(logRecordAddress)
            @_logRecordSocket.subscribe Const.EVERY_CHANNEL
            @_records = []
        catch ex
            console.error "couldn't find address for diag service!"
            console.error ex
        return null

    @getRecords = (from, levels) =>
        records = []
        if @_records.length > 0
            for rec in @_records
                if rec.time >= from and rec.level in levels
                    records.push rec
        return records

    @_onRecord: (channel, data) =>
        try
            record = DiagProto.parse data, "virtdb.interface.pb.LogRecord"
            processedRecord = @_processLogRecord record
            if processedRecord.level in @LEVELS
                @_records.push processedRecord
            if @_records.length > DiagConnector.MAX_STORED_MESSAGE_COUNT
                @_records.splice 0, 1

        catch ex
            log.debug "Couldn't process diag message", V_(ex), V_(record)

    @_processLogRecord: (record) =>
        logRecord = {}
        logRecord.process = @_processProcessInfo record
        logRecord.time = (new Date).getTime()
        logRecord.entry = []
        header =  record.Headers[0]
        for _data in record.Data when _data.HeaderSeqNo is header.SeqNo
            data = _data
            break
        logRecord.level = header.Level
        logRecord.location =
                file: @_findSymbolValue(record.Symbols, header.FileNameSymbol)
                function: @_findSymbolValue(record.Symbols, header.FunctionNameSymbol)
                line: header.LineNumber
        logRecord.parts = []
        index = 0
        for part in header.Parts
            if part.IsVariable && part.HasData
                _part =
                    name: @_findSymbolValue record.Symbols, part.PartSymbol
                    value: @_findValue data.Values[index]
                index++
                logRecord.parts.push _part
            else if part.HasData
                _part =
                    name: null
                    value: @_findValue data.Values[index]
                index++
                logRecord.parts.push _part
            else if part.PartSymbol?
                _part =
                    name: @_findSymbolValue record.Symbols, part.PartSymbol
                    value: null
                logRecord.parts.push _part
        return logRecord

    @_processProcessInfo: (record) =>
        dateFormat = "YYYYMMDDHHmmss"
        return process =
            name: @_findSymbolValue(record.Symbols, record.Process.NameSymbol)
            host: @_findSymbolValue(record.Symbols, record.Process.HostSymbol)
            startTime: (moment record.Process.StartDate.toString() + record.Process.StartTime.toString(), dateFormat).unix()

    @_findSymbolValue: (symbols, seqNo) =>
        for symbol in symbols when symbol.SeqNo is seqNo
            return symbol.Value

    @_findValue: (values) =>
        if values.IsNull[0]
            return null
        switch values.Type
            when "STRING"
                return values.StringValue[0]
            when "INT32"
                return values.Int32Value[0]
            when "INT64"
                return values.Int64Value[0]
            when "UINT32"
                return values.UInt32Value[0]
            when "UINT64"
                return values.UInt64Value[0]
            when "DOUBLE"
                return values.DoubleValue[0]
            when "FLOAT"
                return values.FloatValue[0]
            when "BOOL"
                return values.BoolValue[0]
            when "BYTES"
                return values.BytesValue[0]
            else # "DATE", "TIME", "DATETIME", "NUMERIC", "INET4", "INET6", "MAC", "GEODATA"
                return values.StringValue[0]

module.exports = DiagConnector
