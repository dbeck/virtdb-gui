CacheHandler = require "./cache_handler"
MetadataConnection = require "./metadata_connection"
log = (require "virtdb-connector").log
V_ = log.Variable

class MetadataHandler

    @TABLE_NAME_SEPARATOR = "."

    constructor: ->

    getTableList: (provider, search, from, to, filterList, onReady) =>
        try
            tableListRequest = @_createTableListMessage()

            metadata = CacheHandler.get(@_getCacheKey provider, tableListRequest)
            if metadata?
                @_processTableListResponse metadata, onReady
                return

            metadataConnection = new MetadataConnection(CIM)
            metadataConnection.getMetadata tableListRequest, (metadata) =>
                if metadata.Tables.length > 0
                    CacheHandler.set(@_getCacheKey(provider, tableListRequest), metadata)
                @_processTableListResponse metadata, search, from, to, filterList, onReady
        catch ex
        log.error V_(ex)
        throw ex

    getTableMetaData: (provider, table, onReady) =>
        try
            tableMetadataRequest = @_createTableMetadataMessage()

            metadata = CacheHandler.get(@_getCacheKey provider, tableMetadataRequest)
            if metadata?
                onReady metadata
                return

            metadataConnection = new MetadataConnection(CIM)
            metadataConnection.getMetadata tableMetadataRequest, (metadata) =>
                if metadata.Tables.length > 0
                    CacheHandler.set(@_getCacheKey(provider, tableMetadataRequest), metadata)
                onReady metadata
        catch ex
        log.error V_(ex)
        throw ex

    _processTableListResponse: (metadata, search, from, to, filterList, onReady) =>
        tables = @_createTableList metadata
        tables = @_filterTableList tables, search, filterList
        result = @_reduceTableList tables, from, to
        onReady result

    _createTableListMessage: =>
        return metadataRequest =
            Name: ".*"
            Schema: ".*"
            WithFields: false

    _createTableMetadataMessage: (table) =>
        tableObj = _convertTableToObject table
        return metadataRequest =
            Schema: tableObj.Schema,
            Name: tableObj.Name,
            WithFields: true

    _convertTableToObject: (table) =>
        tableObj = {}
        tableElements = table.split(@TABLE_NAME_SEPARATOR)
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
                tableList.push table.Schema + @TABLE_NAME_SEPARATOR + table.Name
            else
                tableList.push table.Name
        return tableList

    _filterTableList: (tables, search, from, to, filterList) =>
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

    _getCacheKey: (provider, request) =>
        return provider + "_" + JSON.stringify request

module.exports = MetadataHandler
