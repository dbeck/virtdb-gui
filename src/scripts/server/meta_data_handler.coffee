Cache = require "./cache_handler"
Endpoints = require "./endpoints"
VirtDB = require "virtdb-connector"
Const = VirtDB.Const
log = VirtDB.log
V_ = log.Variable
MetaDataProto = (require "virtdb-proto").meta_data

TABLE_NAME_SEPARATOR = "."

putMetadataInCache = (cacheKey, metadata, isPermanent) ->
    if metadata.Tables.length > 0
        Cache.set cacheKey, metadata
        if isPermanent
            Cache.addKeyExpirationListener cacheKey, refillMetadataCache

refillMetadataCache = (key) ->
    cacheKey = Cache.parseCacheKeyOfMetadata key
    if cacheKey?
        [provider, request] = cacheKey
        sendMetaDataRequest provider, request, (err, metadata) ->
            if not err?
                putMetadataInCache key, metadata, true

processTableListResponse = (metadata, search, from, to, filterList) ->
    tables = createTableList metadata
    tables = filterTableList tables, search, filterList
    result = createTableListResult tables, from, to
    return result

createTableListMessage = (token) ->
    metadataRequest =
        Name: ".*"
        Schema: ".*"
        WithFields: false
    if token?
        metadataRequest["UserToken"] = token
    return metadataRequest

createTableMetadataMessage = (table, token) ->
    tableObj = convertTableToObject table
    metadataRequest =
        Schema: tableObj.Schema,
        Name: tableObj.Name,
        WithFields: true
    if token?
        metadataRequest["UserToken"] = token
    return metadataRequest

convertTableToObject = (table) ->
    tableObj = {}
    tableElements = table.split TABLE_NAME_SEPARATOR
    #if no schema
    if tableElements.length is 1
        tableObj.Name ?= tableElements[0]
    #if schema and tablename is also exist
    else if tableElements.length is 2
        tableObj.Name ?= tableElements[1]
        tableObj.Schema ?= tableElements[0]
    else
        return null
    return tableObj

createTableList = (metadata) ->
    tableList = []
    for table in metadata.Tables
        if table.Schema?
            tableList.push table.Schema + TABLE_NAME_SEPARATOR + table.Name
        else
            tableList.push table.Name
    return tableList

filterTableList = (tables, search, filterList) ->
    results = []
    if filterList?.length > 0
        for tableToFind in filterList
            for table in tables
                if tableToFind is table or tableToFind is (table.split("."))[1]
                    results.push table
    else if not search? or search.length is 0
        results = tables
    else
        for table in tables
            if table.toLowerCase().indexOf(search.toLowerCase()) isnt -1
                results.push table
    return results

createTableListResult = (tables, from, to) ->
    realFrom = Math.max(0, from - 1)
    realTo = Math.min(to - 1, Math.max(tables.length - 1, 0))
    return result =
        from: realFrom
        to: realTo
        count: tables.length
        results: tables[realFrom..realTo]

sendMetaDataRequest = (name, request, cb) ->
    message = MetaDataProto.serialize request, "virtdb.interface.pb.MetaDataRequest"
    VirtDB.sendRequest name, Const.ENDPOINT_TYPE.META_DATA, message, (parseReply name, cb)
    VirtDB.MonitoringService.bumpStatistic "Metadata request sent"

parseReply = (name, callback) ->
    return (err, message) ->
        try
            if err?
                throw err
            try
                reply = MetaDataProto.parse message, "virtdb.interface.pb.MetaData"
            catch ex
                VirtDB.MonitoringService.requestError name, Const.REQUEST_ERROR.INVALID_REQUEST, ex.toString()
                throw ex
            callback null, reply
        catch ex
            callback ex, null

MetaDataHandler =
    emptyProviderCache: (provider) ->
        for key in Cache.listKeys()
            cacheKey = Cache.parseCacheKeyOfMetadata key
            if cacheKey?
                [cachedProvider, request] = cacheKey
                if cachedProvider is provider
                    Cache.delete key

    getTableList: (provider, search, from, to, filterList, token, onReady) ->
        try
            tableListRequest = createTableListMessage token

            cacheKey = Cache.generateCacheKeyForMetadata provider, tableListRequest
            cachedResponse = Cache.get cacheKey

            if cachedResponse?
                metadata = cachedResponse
                result = processTableListResponse metadata, search, from, to, filterList
                onReady null, result
            else
                sendMetaDataRequest provider, tableListRequest, (err, metadata) ->
                    result = null
                    if not err?
                        putMetadataInCache cacheKey, metadata, true
                        result = processTableListResponse metadata, search, from, to, filterList
                    onReady err, result
        catch ex
            log.error V_(ex)
            throw ex

    getTableDescription: (provider, table, token, onReady) ->
        try
            tableMetadataRequest = createTableMetadataMessage table, token

            cacheKey = Cache.generateCacheKeyForMetadata provider, tableMetadataRequest
            cachedResponse = Cache.get cacheKey
            if cachedResponse?
                onReady null, cachedResponse
            else
                sendMetaDataRequest provider, tableMetadataRequest, (err, metadata) ->
                    if err?
                        onReady err, null
                        return
                    if metadata.Tables.length is 0
                        err = new Error("No tables in table metadata #{provider}, #{table}")
                        log.error "No tables in table metadata", V_(provider), V_(table), V_(metadata)
                        metadata = null
                    else
                        receivedTable = metadata.Tables[0]
                        if receivedTable.Fields.length is 0
                            err = new Error("No fields in table metadata #{provider}, #{table}")
                            log.error "No fields in table metadata", V_(provider), V_(table), V_(metadata)
                            metadata = null
                    if metadata?
                        putMetadataInCache cacheKey, metadata, false
                    onReady err, metadata
            return
        catch ex
            log.error V_(ex)
            throw ex

module.exports = MetaDataHandler
