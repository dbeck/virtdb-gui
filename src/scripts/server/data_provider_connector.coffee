zmq = require "zmq"
fs = require "fs"
protobuf = require "node-protobuf"
log = require "loglevel"
ServiceConfig = require "./svcconfig_connector"
FieldData = require "./fieldData"
Const = require "./constants"
Config = require "./config"

log.setLevel "debug"
require("source-map-support").install()

DataProto = new protobuf(fs.readFileSync("proto/data.pb.desc"))
MetaDataProto = new protobuf(fs.readFileSync("proto/meta_data.pb.desc"))

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


    @getTableMeta: (provider, schema, table, onReady) =>
        @checkTableMetaCache(provider)

        if not @_tableMetaCache[provider][table]?
            log.debug "The requested table is not in cache."
            log.debug "Getting table meta from provider"
            connection = DataProviderConnection.getConnection(provider)
            #TODO We should use the schema given as parameter
            connection.getMetadata Config.Values.SCHEMA, table, true, (metaData) =>
                tableMeta = metaData.Tables[0]
                @_tableMetaCache[provider][table] = tableMeta
                onReady @_tableMetaCache[provider][table]
        else
            log.debug "The requested table is in cache."
            onReady @_tableMetaCache[provider][table]


    @getTableNames: (provider, schema, onReady) =>
        @checkTableNamesCache(provider)

        if @_tableNamesCache[provider].length is 0
            log.debug "Cache for the current provider is empty."
            log.debug "Getting table names from provider"
            connection = DataProviderConnection.getConnection(provider)
            #TODO We should use the schema given as parameter
            connection.getMetadata Config.Values.SCHEMA, Config.Values.TABLE_REGEXP, false, (metaData) =>
                @_tableNamesCache[provider] = (table.Name for table in metaData.Tables)
                onReady @_tableNamesCache[provider]
        else
            log.debug "Getting table names from cache"
            onReady @_tableNamesCache[provider]


    @getData: (provider, schema, table, count, onData) =>
        @checkTableMetaCache(provider)

        #TODO We should use the schema given as parameter
        @getTableMeta provider, Config.Values.SCHEMA, table, (tableMeta) =>
            connection = DataProviderConnection.getConnection(provider)
            connection.getData schema, table, tableMeta.Fields, count, (data) =>
                onData data

class DataProviderConnection

    @getConnection: (provider) ->
        addresses = ServiceConfig.getInstance().getAddresses provider
        try
            metaDataAddress = addresses[Const.ENDPOINT_TYPE.META_DATA][Const.SOCKET_TYPE.REQ_REP][0]
            columnAddress = addresses[Const.ENDPOINT_TYPE.COLUMN][Const.SOCKET_TYPE.PUB_SUB][0]
            queryAddress = addresses[Const.ENDPOINT_TYPE.QUERY][Const.SOCKET_TYPE.PUSH_PULL][0]
        catch ex
            log.error "Couldn't find addresses for provider: #{provider}!"
            throw ex
        return new DataProviderConnection(metaDataAddress, columnAddress, queryAddress)

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
            log.debug "Got metadata: ", metaData
            onMetaData metaData
            return

        try
            log.debug "Sending MetaDataRequest message: " + JSON.stringify metaDataRequest
            @_metaDataSocket.send MetaDataProto.serialize metaDataRequest, "virtdb.interface.pb.MetaDataRequest"
        catch e
            log.error e

    getData: (schema, table, fields, count, onColumn) =>

        @queryId = Math.floor((Math.random() * 100000) + 1)

        query =
            QueryId: @queryId
            Table: table
            Fields: fields
            Limit: count

        @_columnReceiver = new ColumnReceiver(onColumn, fields)
        @_columnSocket = zmq.socket(Const.ZMQ_SUB)
        @_columnSocket.connect(@columnAddress)
        @_columnSocket.subscribe @queryId.toString()
        @_columnSocket.on "message", (channel, data) =>
            log.debug "Got column on channel: ", channel.toString()
            column = DataProto.parse data, "virtdb.interface.pb.Column"
            log.debug "Data: ", column
            @_columnReceiver.add column
            return

        @_querySocket = zmq.socket(Const.ZMQ_PUSH)
        @_querySocket.connect(@queryAddress)

        try
            log.debug "Sending Query message: " + JSON.stringify query
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
        @_columns = {}
        @_columnEndOfData = {}
        for field in @_fields
            @_columnEndOfData[field.name] = false

    add: (column) =>
        if @_columns[column.Name]?
            #TODO append data properly
            log.debug "Append data to the already received ones"
        else
            @_columns[column.Name] = FieldData.get(column)

        if not column.EndOfData
            log.debug "More data will come in this column."
        @_columnEndOfData[column.Name] = column.EndOfData

        if @_checkReceivedColumns()
            @_readyCallback @_columns

        return

    _checkReceivedColumns: () =>
        for field in @_fields
            if not @_columns[field.Name]? or not @_columnEndOfData[field.Name]
                return false
        return true


module.exports = DataProvider
