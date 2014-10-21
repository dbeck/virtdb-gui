zmq = require "zmq"
fs = require "fs"
protobuf = require "node-protobuf"
log = require "loglevel"
lz4 = require "lz4"
EndpointService = require "./endpoint_service"
FieldData = require "./fieldData"
Const = (require "virtdb-connector").Constants
Config = require "./config"
util = require "util"

log.setLevel "debug"
require("source-map-support").install()

DataProto = new protobuf(fs.readFileSync("common/proto/data.pb.desc"))
MetaDataProto = new protobuf(fs.readFileSync("common/proto/meta_data.pb.desc"))
CommonProto = new protobuf(fs.readFileSync("common/proto/common.pb.desc"))

class DataProvider

    @_tableNamesCache = {}
    @_tableMetaCache = []

    @checkTableNamesCache: (provider, schema) =>
        if not @_tableNamesCache[provider]?
            log.debug "Table name cache for the provider: #{provider} is not existing yet."
            @_tableNamesCache[provider] = []

    @checkTableMetaCache: (provider) =>
        if not @_tableMetaCache[provider]?
            log.debug "Table meta cache for the provider: #{provider} is not existing yet."
            @_tableMetaCache[provider] = []


    @getTableMeta: (provider, tableName, onReady) =>
        @checkTableMetaCache(provider)

        if not @_tableMetaCache[provider][table]?
            log.debug "The requested table is not in cache."
            log.debug "Getting table meta from provider"
            connection = DataProviderConnection.getConnection(provider)
            try
                table = @_processTableName tableName
                connection.getMetadata table.Schema, table.Name, true, (metaData) =>
                    tableMeta = metaData.Tables[0]
                    @_tableMetaCache[provider][table] = tableMeta
                    onReady @_tableMetaCache[provider][table]
            catch ex
                log.error "Couldn't get table meta.", ex
                onReady []
        else
            log.debug "The requested table is in cache."
            onReady @_tableMetaCache[provider][table]

    @getData: (provider, tableName, count, onData) =>
        @getTableMeta provider, tableName, (tableMeta) =>
            connection = DataProviderConnection.getConnection(provider)
            try
                connection.getData tableMeta.Schema, tableMeta.Name, tableMeta.Fields, count, (data) =>
                    onData data
            catch e
                onData []

    @getTableNames: (provider, search, from, to, onReady) =>
        try
            @_fillTableNamesCache provider, () =>
                results = []
                if not search?
                    results = @_tableNamesCache[provider]
                else
                    for table in @_tableNamesCache[provider]
                        if table.toLowerCase().indexOf(search.toLowerCase()) isnt -1
                            results.push table
                realFrom = Math.max(0, from - 1)
                realTo = Math.min(to - 1, Math.max(results.length - 1, 0))
                result =
                    from: realFrom
                    to: realTo
                    count: results.length
                    results: results[realFrom..realTo]
                onReady result
        catch ex
            log.error "Couldn't get table names.", ex
            onReady []

    @_fillTableNamesCache: (provider, onReady) =>
        @checkTableNamesCache(provider)
        if @_tableNamesCache[provider].length isnt 0
            log.debug "Serving table names from cache.", provider
            onReady()
        else
            log.debug "Cache for the current provider is empty."
            log.debug "Getting table names from provider"
            connection = DataProviderConnection.getConnection(provider)
            try
                connection.getMetadata ".*", ".*", false, (metaData) =>
                    @_tableNamesCache[provider] = []
                    for table in metaData.Tables
                        if table.Schema?
                            @_tableNamesCache[provider].push table.Schema + "." + table.Name
                        else
                            @_tableNamesCache[provider].push table.Name
                    onReady()
            catch ex
                log.error "Couldn't fill table names cache.", provider, ex
                throw ex
        return

    @_processTableName: (tableDesc) =>
        table = {}
        tableElements = tableDesc.split(".")
        #if no schema
        if tableElements.length is 1
            table.Name ?= tableElements[0]
        #if schema and tablename is also exist
        else if tableElements.length is 2
            table.Name ?= tableElements[1]
            table.Schema ?= tableElements[0]
        else
            throw "Something wrong with the format of the table name."
        return table

class DataProviderConnection

    @getConnection: (provider) ->
        try
            addresses = EndpointService.getInstance().getComponentAddresses provider
            metaDataAddress = addresses[Const.ENDPOINT_TYPE.META_DATA][Const.SOCKET_TYPE.REQ_REP][0]
            columnAddress = addresses[Const.ENDPOINT_TYPE.COLUMN][Const.SOCKET_TYPE.PUB_SUB][0]
            queryAddress = addresses[Const.ENDPOINT_TYPE.QUERY][Const.SOCKET_TYPE.PUSH_PULL][0]
            return new DataProviderConnection(metaDataAddress, columnAddress, queryAddress)
        catch ex
            log.error "Couldn't find addresses for provider!", provider
        return null

    _metaDataSocket: null
    _querySocket: null
    _columnSocket: null

    _columnReceiver: null

    constructor: (@metaDataAddress, @columnAddress, @queryAddress) ->

    getMetadata: (schema, table, withFields, onMetaData) =>
        metaDataRequest =
            Name: table
            Schema: schema
            WithFields: withFields

        @_metaDataSocket = zmq.socket(Const.ZMQ_REQ)
        @_metaDataSocket.connect(@metaDataAddress)
        @_metaDataSocket.on "message", (data) =>
            metaData = MetaDataProto.parse data, "virtdb.interface.pb.MetaData"
            log.trace "Got metadata:", metaData
            onMetaData metaData
            return

        try
            log.debug "Sending MetaDataRequest message:", JSON.stringify metaDataRequest
            @_metaDataSocket.send MetaDataProto.serialize metaDataRequest, "virtdb.interface.pb.MetaDataRequest"
        catch e
            log.error e

    getData: (schema, table, fields, count, onColumn) =>

        if not schema?
            schema = ""

        @queryId = Math.floor((Math.random() * 100000) + 1)

        query =
            QueryId: @queryId
            Table: table
            Fields: fields
            Limit: count
            Schema: schema

        @_columnReceiver = new ColumnReceiver(onColumn, fields)
        @_columnSocket = zmq.socket(Const.ZMQ_SUB)
        @_columnSocket.connect(@columnAddress)
        @_columnSocket.subscribe @queryId.toString()
        @_columnSocket.on "message", (channel, data) =>
            column = DataProto.parse data, "virtdb.interface.pb.Column"
            log.debug "Got column on channel: channel=" + channel.toString() + " column=#{column.Name}"
            if column.CompType is "LZ4_COMPRESSION"
                uncompressedData = new Buffer(column.UncompressedSize)
                size = lz4.decodeBlock(column.CompressedData, uncompressedData)
                uncompressedData = uncompressedData.slice(0, size)
                column.Data = CommonProto.parse uncompressedData, "virtdb.interface.pb.ValueType"
            log.trace "Column: ", column

            @_columnReceiver.add column
            return

        @_querySocket = zmq.socket(Const.ZMQ_PUSH)
        @_querySocket.connect(@queryAddress)

        try
            log.debug "Sending Query message: id=#{@queryId} table=#{table}"
            @_querySocket.send DataProto.serialize query, "virtdb.interface.pb.Query"
        catch e
            log.error e

    close: () =>
        if @_metaDataSocket?
            @_metaDataSocket.close()
        if @_columnSocket?
            @_columnSocket.close()
        if @_querySocket?
            @_querySocket.close()

class ColumnReceiver
    _columns: null
    _readyCallback: null
    _fields: null
    _columnEndOfData: null

    constructor: (@_readyCallback, @_fields) ->
        @_columns = []
        @_columnEndOfData = {}
        for field in @_fields
            @_columnEndOfData[field.name] = false

    add: (column) =>
        @_add column.Name, FieldData.get column

        if not column.EndOfData
            log.debug "More data will come in this column."
        @_columnEndOfData[column.Name] = column.EndOfData

        if @_checkReceivedColumns()
            @_readyCallback @_columns

        return

    _contains: (columnName) =>
        for column in @_columns
            if column.Name == columnName
                return true
        return false

    _add: (columnName, data) =>
        if @_contains columnName
            #TODO append data properly
            log.debug "Append data to the already received ones"
        else
            @_columns.push
                Name: columnName
                Data: data

    _checkReceivedColumns: () =>
        @_fields.length == @_columns.length


module.exports = DataProvider
