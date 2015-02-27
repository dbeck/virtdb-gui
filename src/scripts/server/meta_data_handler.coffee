CacheHandler = require "./cache_handler"
MetadataConnection = require "./metadata_connection"
Endpoints = require "./endpoints"
VirtDBConnector = require "virtdb-connector"
Const = VirtDBConnector.Constants
log = VirtDBConnector.log
V_ = log.Variable

class MetadataHandler

    @TABLE_NAME_SEPARATOR = "."

    constructor: ->

    getTableList: (provider, search, from, to, filterList, onReady) =>
        try
            tableListRequest = @_createTableListMessage()

            cacheKey = @_generateCacheKey provider, tableListRequest
            cachedResponse = CacheHandler.get cacheKey

            if cachedResponse?
                metadata = cachedResponse
                result = @_processTableListResponse metadata, search, from, to, filterList
                onReady result
            else
                metadataConnection = MetadataConnection.createInstance Endpoints.getMetadataAddress provider
                metadataConnection.getMetadata tableListRequest, (metadata) =>
                    @_putMetadataInCache cacheKey, metadata, true
                    result = @_processTableListResponse metadata, search, from, to, filterList
                    onReady result
        catch ex
            log.error V_(ex)
            throw ex

    _putMetadataInCache: (cacheKey, metadata, isPermanent) =>
        if metadata.Tables.length > 0
            CacheHandler.set cacheKey, metadata
            if isPermanent
                CacheHandler.addKeyExpirationListener cacheKey, @_refillMetadataCache

    _refillMetadataCache: (key) =>
        [provider, request] = @_parseCacheKey key
        metadataConnection = MetadataConnection.createInstance Endpoints.getMetadataAddress provider
        metadataConnection.getMetadata request, (metadata) =>
            @_putMetadataInCache key, metadata, true
    
    getTableMetadata: (provider, table, onReady) =>
        try
            tableMetadataRequest = @_createTableMetadataMessage(table)

            cacheKey = @_generateCacheKey provider, tableMetadataRequest
            cachedResponse = CacheHandler.get cacheKey
            if cachedResponse?
                onReady cachedResponse
            else
                metadataConnection = MetadataConnection.createInstance Endpoints.getMetadataAddress provider
                metadataConnection.getMetadata tableMetadataRequest, (metadata) =>
                    if metadata.Tables.length > 0
                        CacheHandler.set cacheKey, metadata
                    onReady metadata
            return
        catch ex
            log.error V_(ex)
            throw ex

    _processTableListResponse: (metadata, search, from, to, filterList) =>
        tables = @_createTableList metadata
        tables = @_filterTableList tables, search, filterList
        result = @_createTableListResult tables, from, to
        return result

    _createTableListMessage: =>
        return metadataRequest =
            Name: ".*"
            Schema: ".*"
            WithFields: false

    _createTableMetadataMessage: (table) =>
        tableObj = @_convertTableToObject table
        return metadataRequest =
            Schema: tableObj.Schema,
            Name: tableObj.Name,
            WithFields: true

    _convertTableToObject: (table) =>
        tableObj = {}
        tableElements = table.split(MetadataHandler.TABLE_NAME_SEPARATOR)
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

    _createTableList: (metadata) =>
        tableList = []
        for table in metadata.Tables
            if table.Schema?
                tableList.push table.Schema + MetadataHandler.TABLE_NAME_SEPARATOR + table.Name
            else
                tableList.push table.Name
        return tableList

    _filterTableList: (tables, search, filterList) =>
        results = []
        if filterList.length > 0
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

    _createTableListResult: (tables, from, to) =>
        realFrom = Math.max(0, from - 1)
        realTo = Math.min(to - 1, Math.max(tables.length - 1, 0))
        return result =
            from: realFrom
            to: realTo
            count: tables.length
            results: tables[realFrom..realTo]

    _generateCacheKey: (provider, request) =>
        return provider + "_" + JSON.stringify request

    _parseCacheKey: (key) =>
        parts = key.split "_"
        return [parts[0], (JSON.parse parts[1])]

    @createInstance: =>
        return new MetadataHandler

module.exports = MetadataHandler
