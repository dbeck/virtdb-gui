zmq = require "zmq"
fs = require "fs"
Const = (require "virtdb-connector").Constants
log = (require "virtdb-connector").log
V_ = log.Variable
lz4 = require "lz4"

require("source-map-support").install()

DataProto = (require "virtdb-proto").data
CommonProto = (require "virtdb-proto").common

class DataConnection

    _queryAddress: null
    _columnAddress: null
    _querySocket: null
    _columnSocket: null
    _onColumn: null
    _queryId: null

    constructor: (@_queryAddress, @_columnAddress) ->

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
            @_querySocket.connect(@_queryAddress)
        catch ex
            log.error V_(ex)
            throw ex

    _initColumnSocket: () =>
        try
            @_columnSocket = zmq.socket(Const.ZMQ_SUB)
            @_columnSocket.subscribe @_queryId
            @_columnSocket.connect(@_columnAddress)
            @_columnSocket.on "message", @_onColumnMessage
        catch ex
            log.error V_(ex)
            throw ex

    _onColumnMessage: (channel, message) =>
        try
            column = DataProto.parse message, "virtdb.interface.pb.Column"
            log.trace "got column", V_(channel), V_(column.fields)
            if column.CompType is "LZ4_COMPRESSION"
                uncompressedData = new Buffer(column.UncompressedSize)
                size = lz4.decodeBlock(column.CompressedData, uncompressedData)
                uncompressedData = uncompressedData.slice(0, size)
                column.Data = CommonProto.parse uncompressedData, "virtdb.interface.pb.ValueType"
            @_onColumn column
            return
        catch ex
            log.error V_(ex)
            throw ex

    @createInstance: (queryAddress, columnAddress) =>
        return new DataConnection queryAddress, columnAddress

module.exports = DataConnection
