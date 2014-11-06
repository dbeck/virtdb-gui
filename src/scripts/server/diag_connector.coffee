Config = require "./config"
zmq = require "zmq"
fs = require "fs"
protobuf = require "node-protobuf"
log = require "loglevel"
FieldData = require "./fieldData"

EndpointService = require "./endpoint_service"
FieldData = require "./fieldData"
Const = (require "virtdb-connector").Constants
util = require "util"
moment = require "moment"

DiagProto = new protobuf(fs.readFileSync("common/proto/diag.pb.desc"))
class DiagConnector

    @_records: null
    @_logRecordSocket: null

    @connect: (diagServiceName) =>
        try
            addresses = EndpointService.getInstance().getComponentAddresses diagServiceName
            logRecordAddress = addresses[Const.ENDPOINT_TYPE.LOG_RECORD][Const.SOCKET_TYPE.PUB_SUB][0]
            @_logRecordSocket = zmq.socket(Const.ZMQ_SUB)
            @_logRecordSocket.on "message", @_onRecord
            @_logRecordSocket.connect(logRecordAddress)
            @_logRecordSocket.subscribe Const.EVERY_CHANNEL
        catch ex
            log.error ex
            log.error "Couldn't find address for diag service!"
        return null

    @_onRecord: (channel, data) =>
        log.debug "Log MSG!", (new Buffer(channel)).toString()
        record = DiagProto.parse data, "virtdb.interface.pb.LogRecord"
        @_processLogRecord record

    @_processLogRecord: (record) =>
        logRecord = {}
        logRecord.process = @_processProcessInfo record
        logRecord.time = moment().unix()
        logRecord.entries = []
        for header in record.Headers
            logRecord.entries.push @_processLogEntry header, record
        log.debug util.inspect logRecord, {depth: null}

    @_processLogEntry: (header, record) =>
        entry = {}
        data = {}
        for _data in record.Data when _data.HeaderSeqNo is header.SeqNo
            data = _data
            break
        entry.level = header.Level
        entry.location =
                file: @_findSymbolValue(record.Symbols, header.FileNameSymbol)
                function: @_findSymbolValue(record.Symbols, header.FunctionNameSymbol)
                line: header.LineNumber
        entry.parts = []
        index = 0
        for part in header.Parts
            if part.IsVariable && part.HasData
                _part =
                    name: @_findSymbolValue record.Symbols, part.PartSymbol
                    value: @_findValue data.Values[index]
                index++
                entry.parts.push _part
            else if part.HasData
                _part =
                    name: null
                    value: @_findValue data.Values[index]
                index++
                entry.parts.push _part
            else if part.PartSymbol?
                _part =
                    name: @_findSymbolValue record.Symbols, part.PartSymbol
                    value: null
                entry.parts.push _part
        return entry

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