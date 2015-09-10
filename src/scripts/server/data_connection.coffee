zmq = require "zmq"
fs = require "fs"
VirtDB = require "virtdb-connector"
Const = VirtDB.Const
log = VirtDB.log
V_ = log.Variable
lz4 = require "lz4"
QueryIdGenerator = require "./query_id_generator"

DataProto = (require "virtdb-proto").data
CommonProto = (require "virtdb-proto").common


class DataConnection

    _queryAddresses: null
    _columnAddresses: null
    _connectedColumnAddresses: null
    _querySocket: null
    _columnSocket: null
    _onColumn: null

    constructor: (@_queryAddresses, @_columnAddresses, @_name) ->
        @_connectedColumnAddresses = []

    getData: (loginToken, schema, table, fields, count, onData) =>
        @_onColumn = onData
        queryId = QueryIdGenerator.getNextQueryId()
        @_initColumnSocket(queryId)
        @_initQuerySocket()
        schema ?= ""
        queryMessage =
            QueryId: queryId
            Table: table
            Fields: fields
            Limit: count
            Schema: schema
        if loginToken?
            queryMessage["UserToken"] = loginToken
        try
            log.trace "sending Query message", V_(@queryId), V_(table)
            @_querySocket.send DataProto.serialize queryMessage, "virtdb.interface.pb.Query"
            VirtDB.MonitoringService.bumpStatistic "Data request sent"
            @_closeQuerySocket()
        catch ex
            log.error V_(ex)
            throw ex

    close: =>
        @_closeQuerySocket()
        @_closeColumnSocket()

    _closeQuerySocket: =>
        if @_queryAddresses?
            for addr in @_queryAddresses
                @_querySocket?.disconnect addr
        @_queryAddresses = null
        @_querySocket?.close()
        @_querySocket = null

    _initQuerySocket: =>
        try
            @_querySocket = zmq.socket(Const.ZMQ_PUSH)
            for addr in @_queryAddresses
                @_querySocket.connect addr
        catch ex
            log.error V_(ex)
            throw ex

    _initColumnSocket: (queryId) =>
        try
            @_columnSocket = zmq.socket(Const.ZMQ_SUB)
            @_columnSocket.subscribe queryId
            @_columnSocket.setsockopt zmq.ZMQ_RCVHWM, 100000
            @_columnSocket.on "message", @_onColumnMessage
            for addr in @_columnAddresses
                try
                    @_columnSocket.connect addr
                    @_connectedColumnAddresses.push addr
                    # Only go for the first successful connection for this specific provider.
                    return
                catch ex
                    log.warn "Failed to initiate column socket for:", V_(addr)
            throw new Error "Failed to connect any of the column addresses!"
        catch ex
            log.error V_(ex)
            throw ex

    _closeColumnSocket: =>
        if @_columnAddresses?
            for addr in @_connectedColumnAddresses
                try
                    @_columnSocket.disconnect addr
                catch ex
                    log.error "Failed to disconnect column socket for address:", V_(addr)
        @_connectedColumnAddresses = []
        @_columnAddresses = null
        @_columnSocket?.close()
        @_columnSocket = null

    _onColumnMessage: (channel, message) =>
        try
            column = {}
            try
                column = DataProto.parse message, "virtdb.interface.pb.Column"
            catch ex
                VirtDB.MonitoringService.requestError @_name, Const.REQUEST_ERROR.INVALID_REQUEST, ex.toString()
                throw ex
            if column.CompType is "LZ4_COMPRESSION"
                uncompressedData = new Buffer(column.UncompressedSize)
                size = lz4.decodeBlock(column.CompressedData, uncompressedData)
                uncompressedData = uncompressedData.slice(0, size)
                column.Data = CommonProto.parse uncompressedData, "virtdb.interface.pb.ValueType"
            @_onColumn column, @_closeColumnSocket
            return
        catch ex
            log.error "Error happened when column message received:", V_(ex)
            throw ex

    @createInstance: (queryAddresses, columnAddresses, name) =>
        return new DataConnection queryAddresses, columnAddresses, name

module.exports = DataConnection
