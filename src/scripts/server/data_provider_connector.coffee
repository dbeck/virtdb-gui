CONST = require("./config").Const
zmq = require("zmq")
fs = require("fs")
protobuf = require("node-protobuf")
proto_metadata = new protobuf(fs.readFileSync("proto/meta_data.pb.desc"))
proto_data = new protobuf(fs.readFileSync("proto/data.pb.desc"))
log = require("loglevel")
require('source-map-support').install()
FieldData = require './fieldData'
log.setLevel 'debug'
ServiceConfig = require('./svcconfig_connector')

class DataProvider

    @_tableNamesCache = {}
    @_tableMetaCache = []

    #TODO This function needs to be be deleted ASAP
    @selectSchema: (provider) =>
        if provider is "csv-provider"
            return "data"
        if provider is "sap-provider"
            return ""

    @checkTableNamesCache: (provider, schema) =>
        if not @_tableNamesCache[provider]?
            log.debug "Cache for the provider: #{provider} is not existing yet."
            @_tableNamesCache[provider] = []

    @checkTableMetaCache: (provider) =>
        if not @_tableMetaCache[provider]?
            log.debug "Cache for the provider: #{provider} is not existing yet."
            @_tableMetaCache[provider] = []


    @getTableMeta: (provider, schema, table, onReady) =>
        @checkTableMetaCache(provider)

        if not @_tableMetaCache[provider][table]?
            log.debug "The requested table is not in cache."
            log.debug "Getting table meta from provider"
            connection = DataProviderConnection.getConnection(provider)
            #TODO We should use the schema given as parameter
            connection.getMetadata @selectSchema(provider), table, true, (metaData) =>
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
            connection.getMetadata @selectSchema(provider), ".*", false, (metaData) =>
                @_tableNamesCache[provider] = (table.Name for table in metaData.Tables)
                onReady @_tableNamesCache[provider]
        else
            log.debug "Getting table names from cache"
            onReady @_tableNamesCache[provider]


    @getData: (provider, schema, table, count, onData) =>
        @checkTableMetaCache(provider)
        
        #TODO We should use the schema given as parameter
        @getTableMeta provider, @selectSchema(provider), table, (tableMeta) =>
            connection = DataProviderConnection.getConnection(provider)
            connection.getData schema, table, tableMeta.Fields, count, (data) =>
                onData data

class DataProviderConnection

    @_configService = ServiceConfig.getInstance()

    @getConnection: (provider) ->
        addresses = @_configService.getAddresses provider
        try
            metaDataAddress = addresses["META_DATA"]["REQ_REP"][0]
            columnAddress = addresses["COLUMN"]["PUB_SUB"][0]
            queryAddress = addresses["QUERY"]["PUSH_PULL"][0]
        catch ex
            log.error "Couldn't get provider addresses!"
            throw ex
        return new DataProviderConnection(metaDataAddress, columnAddress, queryAddress)

    _reqRepSocket: null
    _pushPullSocket: null
    _pubSubSocket: null
    _columnReceiver: null

    constructor: (@metaDataAddress, @columnAddress, @queryAddress) ->

    getMetadata: (schema, table, withFields, onMetaData) =>
        metaDataRequest =
            Name: table
            Schema: schema
            WithFields: withFields

        @_reqRepSocket = zmq.socket('req')
        @_reqRepSocket.connect(@metaDataAddress)
        @_reqRepSocket.on "message", (data) =>
            metaData = proto_metadata.parse data, 'virtdb.interface.pb.MetaData'
            log.debug 'Got metadata: ', metaData
            onMetaData metaData
            return

        try
            log.debug "Sending MetaDataRequest message: " + JSON.stringify metaDataRequest
            @_reqRepSocket.send proto_metadata.serialize metaDataRequest, "virtdb.interface.pb.MetaDataRequest"
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
        @_pubSubSocket = zmq.socket('sub')
        @_pubSubSocket.connect(@columnAddress)
        @_pubSubSocket.subscribe @queryId.toString()
        @_pubSubSocket.on "message", (channel, data) =>
            log.debug 'Got column on channel: ', channel.toString()
            column = proto_data.parse data, 'virtdb.interface.pb.Column'
            log.debug 'Data: ', column
            @_columnReceiver.add column
            return

        @_pushPullSocket = zmq.socket('push')
        @_pushPullSocket.connect(@queryAddress)

        try
            log.debug "Sending Query message: " + JSON.stringify query
            @_pushPullSocket.send proto_data.serialize query, "virtdb.interface.pb.Query"
        catch e
            log.error e

    close: () =>
        if @_reqRepSocket?
            @_reqRepSocket.close()
        if @_pubSubSocket?
            @_pubSubSocket.close()
        if @_pushPullSocket?
            @_pushPullSocket.close()

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
