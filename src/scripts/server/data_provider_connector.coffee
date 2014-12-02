Config = require "./config"
zmq = require "zmq"
fs = require "fs"
protobuf = require "node-protobuf"
log = (require "virtdb-connector").log
V_ = log.Variable
lz4 = require "lz4"
EndpointService = require "./endpoint_service"
FieldData = require "./fieldData"
Const = (require "virtdb-connector").Constants
util = require "util"
NodeCache = require "node-cache"
ms = require "ms"

require("source-map-support").install()

DataProto = new protobuf(fs.readFileSync("common/proto/data.pb.desc"))
MetaDataProto = new protobuf(fs.readFileSync("common/proto/meta_data.pb.desc"))
CommonProto = new protobuf(fs.readFileSync("common/proto/common.pb.desc"))

class DataProvider

    @_cacheTTL = null
    @_cacheCheckPeriod = null
    @_tableListCache = null
    @_tableMetaCache = null

    @_onNewCacheTTL: (ttl) =>
        @_cacheTTL = ttl
        @_initTableListCache()

    @_onNewCacheCheckPeriod: (checkPeriod) =>
        @_cacheCheckPeriod = checkPeriod
        @_initTableListCache()

    @_createCache: =>
        options = {}
        if @_cacheCheckPeriod?
            options["checkperiod"] = @_cacheCheckPeriod
        if @_cacheTTL?
            options["stdTTL"] = @_cacheTTL
        cache = new NodeCache(options)

    @_initTableListCache: =>
        @_tableListCache = @_createCache()
        @_tableListCache.on "expired", (key, value) =>
            log.debug "table list cache expired", V_(key)

    @_initTableMetaCache: (provider) =>
        if not @_tableMetaCache?
            @_tableMetaCache = {}
        @_tableMetaCache[provider] = @_createCache()
        @_tableMetaCache[provider].on "expired", (key, value) =>
            log.debug "table meta cache expired", V_(key)

    @checkTableMetaCache: (provider) =>
        try
            if @_tableMetaCache? and @_tableMetaCache[provider]?
                return
            log.trace "table meta cache is not existing yet", V_(provider)
            @_initTableMetaCache(provider)
        catch ex
            log.error V_(ex)
            throw ex

    @getTableMeta: (provider, tableName, onReady) =>
        try
            @checkTableMetaCache(provider)

            cachedTable = @_tableMetaCache[provider].get(tableName)
            if cachedTable? and Object.keys(cachedTable).length is 0
                log.debug "requested meta data is not in cache, getting table meta from provider", V_(provider), V_(tableName)
                connection = DataProviderConnection.getConnection(provider)
                table = @_processTableName tableName
                connection.getMetadata table.Schema, table.Name, true, (metaData) =>
                    tableMeta = metaData.Tables[0]
                    @_tableMetaCache[provider].set(tableName, tableMeta)
                    onReady tableMeta
            else
                log.debug "requested meta data is in cache", V_(provider), V_(tableName)
                onReady cachedTable[tableName]
        catch ex
            log.error V_(ex)
            throw ex

    @getData: (provider, tableName, count, onData) =>
        try
            @getTableMeta provider, tableName, (tableMeta) =>
                connection = DataProviderConnection.getConnection(provider)
                connection.getData tableMeta.Schema, tableMeta.Name, tableMeta.Fields, count, (data) =>
                    log.debug "meta data received", V_(tableMeta.Name)
                    onData data
        catch ex
            log.error V_(ex)
            throw ex

    @getTableNames: (provider, search, from, to, tables, onReady) =>
        try
            @_fillTableNamesCache provider, (tableNameList) =>
                results = []
                if tables.length > 0
                    for table in tables
                        for tableName in tableNameList
                            if table is tableName or table is (tableName.split("."))[1]
                                results.push tableName
                else if not search? or search.length is 0
                    results = tableNameList
                else
                    for table in tableNameList
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
            log.error V_(ex)
            throw ex

    @_fillTableNamesCache: (provider, onReady) =>
        try
            tableNameList = @_tableListCache.get(provider)[provider]
            if util.isArray tableNameList
                log.debug "getting table list from cache.", V_(provider)
                onReady tableNameList
            else
                log.debug "cache for the current provider is empty, getting table list from provider", V_(provider)
                connection = DataProviderConnection.getConnection(provider)
                connection.getMetadata ".*", ".*", false, (metaData) =>
                    tableList = []
                    for table in metaData.Tables
                        if table.Schema?
                            tableList.push table.Schema + "." + table.Name
                        else
                            tableList.push table.Name
                    if tableList.length > 0
                        @_tableListCache.set(provider, tableList)
                    onReady tableList
            return
        catch ex
            log.error V_(ex)
            throw ex

    @_processTableName: (tableDesc) =>
        try
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
                throw Error "something wrong with the format of the table name."
            return table
        catch ex
            log.error V_(ex)
            throw ex

class DataProviderConnection

    @getConnection: (provider) ->
        try
            addresses = EndpointService.getInstance().getComponentAddresses provider
            metaDataAddress = addresses[Const.ENDPOINT_TYPE.META_DATA][Const.SOCKET_TYPE.REQ_REP][0]
            columnAddress = addresses[Const.ENDPOINT_TYPE.COLUMN][Const.SOCKET_TYPE.PUB_SUB][0]
            queryAddress = addresses[Const.ENDPOINT_TYPE.QUERY][Const.SOCKET_TYPE.PUSH_PULL][0]
            return new DataProviderConnection(metaDataAddress, columnAddress, queryAddress)
        catch ex
            log.error V_(ex)
            throw ex

    _metaDataSocket: null
    _querySocket: null
    _columnSocket: null
    _columnReceiver: null

    constructor: (@metaDataAddress, @columnAddress, @queryAddress) ->

    getMetadata: (schema, table, withFields, onMetaData) =>
        try
            metaDataRequest =
                Name: table
                Schema: schema
                WithFields: withFields
            @_metaDataSocket = zmq.socket(Const.ZMQ_REQ)
            @_metaDataSocket.connect(@metaDataAddress)
            @_metaDataSocket.on "message", (data) =>
                try
                    metaData = MetaDataProto.parse data, "virtdb.interface.pb.MetaData"
                    log.trace "got metadata", V_(schema), V_(table)
                    onMetaData metaData
                    return
                catch ex
                    log.error V_(ex)
                    throw ex

            log.trace "sending MetaDataRequest message", V_(metaDataRequest)
            @_metaDataSocket.send MetaDataProto.serialize metaDataRequest, "virtdb.interface.pb.MetaDataRequest"
        catch ex
            log.error V_(ex)
            throw ex

    getData: (schema, table, fields, count, onColumn) =>
        try
            schema ?= ""
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
                try
                    column = DataProto.parse data, "virtdb.interface.pb.Column"
                    log.trace "got column", V_(channel), V_(column.fields)
                    if column.CompType is "LZ4_COMPRESSION"
                        uncompressedData = new Buffer(column.UncompressedSize)
                        size = lz4.decodeBlock(column.CompressedData, uncompressedData)
                        uncompressedData = uncompressedData.slice(0, size)
                        column.Data = CommonProto.parse uncompressedData, "virtdb.interface.pb.ValueType"
                    @_columnReceiver.add column
                    return
                catch ex
                    log.error V_(ex)
                    throw ex

            @_querySocket = zmq.socket(Const.ZMQ_PUSH)
            @_querySocket.connect(@queryAddress)

            log.trace "sending Query message", V_(@queryId), V_(table)
            @_querySocket.send DataProto.serialize query, "virtdb.interface.pb.Query"
        catch ex
            log.error V_(ex)
            throw ex

    close: () =>
        try
            if @_metaDataSocket?
                @_metaDataSocket.close()
            if @_columnSocket?
                @_columnSocket.close()
            if @_querySocket?
                @_querySocket.close()
        catch ex
            log.error V_(ex)
            throw ex

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
        @_columns.push
            Name: columnName
            Data: data

    _checkReceivedColumns: () =>
        @_fields.length == @_columns.length

Config.addConfigListener Config.CACHE_PERIOD, DataProvider._onNewCacheCheckPeriod
Config.addConfigListener Config.CACHE_TTL, DataProvider._onNewCacheTTL


module.exports = DataProvider
