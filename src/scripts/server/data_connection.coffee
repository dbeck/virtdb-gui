zmq = require "zmq"
fs = require "fs"
Const = (require "virtdb-connector").Const
log = (require "virtdb-connector").log
V_ = log.Variable
lz4 = require "lz4"

require("source-map-support").install()

DataProto = (require "virtdb-proto").data
CommonProto = (require "virtdb-proto").common

class DataConnection

    _queryAddresses: null
    _columnAddresses: null
    _querySocket: null
    _columnSocket: null
    _onColumn: null
    _queryId: null

    constructor: (@_queryAddresses, @_columnAddresses) ->

    getData: (schema, table, fields, count, onData) =>
        @_onColumn = onData
        @_queryId = Math.floor((Math.random() * 100000) + 1) + ""
        @_initQuerySocket()
        @_initColumnSocket(@_queryId)
        schema ?= ""
        queryMessage =
            QueryId: @_queryId
            Table: table
            Fields: fields
            Limit: count
            Schema: schema
        try
            log.trace "sending Query message", V_(@queryId), V_(table)
            @_querySocket.send DataProto.serialize queryMessage, "virtdb.interface.pb.Query"
        catch ex
            log.error V_(ex)
            throw ex

    _initQuerySocket: =>
        try
            @_querySocket = zmq.socket(Const.ZMQ_PUSH)
            for addr in @_queryAddresses
                @_querySocket.connect addr
        catch ex
            log.error V_(ex)
            throw ex

    _initColumnSocket: () =>
        try
            @_columnSocket = zmq.socket(Const.ZMQ_SUB)
            @_columnSocket.subscribe @_queryId
            @_columnSocket.setsockopt 'ZMQ_RCVHWM', 100000
            @_columnSocket.on "message", @_onColumnMessage
            for addr in @_columnAddresses
                @_columnSocket.connect addr
        catch ex
            log.error V_(ex)
            throw ex

    _onColumnMessage: (channel, message) =>
        try
            column = DataProto.parse message, "virtdb.interface.pb.Column"
            if column.CompType is "LZ4_COMPRESSION"
                uncompressedData = new Buffer(column.UncompressedSize)
                size = lz4.decodeBlock(column.CompressedData, uncompressedData)
                uncompressedData = uncompressedData.slice(0, size)
                column.Data = CommonProto.parse uncompressedData, "virtdb.interface.pb.ValueType"
            @_onColumn column
            return
        catch ex
            log.error "Error happened when column message received:", V_(ex)
            throw ex

    @createInstance: (queryAddresses, columnAddresses) =>
        return new DataConnection queryAddresses, columnAddresses

module.exports = DataConnection
