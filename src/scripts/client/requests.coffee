module.exports = class Requests

    _address: null
    _providerName: null

    constructor: (@_address) ->

    setDataProvider: (@_providerName) =>

    _endpoints: '/api/endpoints'

    _dataProviderMetaDataTableNames: '/api/data_provider/{0}/meta_data/table_names/search/{1}/from/{2}/to/{3}/id/{4}'
    _dataProviderMetaDataTable: '/api/data_provider/{0}/meta_data/table/{1}/id/{2}'
    _dataProviderDataTable: '/api/data_provider/{0}/data/table/{1}/count/{2}/id/{3}'
    _dataProviderDataTableField: '/api/data_provider/{0}/data/table/{1}/field/{2}/count/{3}'

    _dbConfig: 'api/db_config'

    endpoints: () =>
        return @_address + @_endpoints

    metaDataTableNames: (search, from, to, id) =>
        return @_address + formatString(@_dataProviderMetaDataTableNames, @_providerName, search, from, to, id)

    metaDataTable: (table, id) =>
        return @_address + formatString(@_dataProviderMetaDataTable, @_providerName, table, id)

    dataTable: (table, count, id) =>
        return @_address + formatString(@_dataProviderDataTable, @_providerName, table, count, id)

    dataTableField: (table, field, count) =>
        return @_address + formatString(@_dataProviderDataTableField, @_providerName, table, field, count)

    dbConfig: () =>
        return @_address + @_dbConfig

    formatString = (format, args...) =>
        return format.replace /{(\d+)}/g, (match, number) ->
          return if typeof args[number] != 'undefined' then encodeURIComponent(args[number]) else match
