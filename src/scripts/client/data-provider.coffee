app = angular.module 'virtdb-data-provider', []

app.controller 'DataProviderController', ['$scope', '$http', ($scope, $http) ->

    @requests = new Requests("")
    @currentProvider = ''
    @providers = []

    @tableMetaData = {}
    @tableData = {}
    @tableList = []
    @fieldList = []
    @currentTable = ''
    @currentField = ''
    @limit = 10
    @rowIndexes = [0..@limit-1]
    @isHeaderColumn = false

    @getDataProviders = () ->
        $http.get(@requests.endpoints()).success (data) =>
            services = {}
            for endpoint in data
                services[endpoint.Name] ?= []
                services[endpoint.Name].push(endpoint.SvcType)
            for endpointName, serviceTypes of services
                if "META_DATA" in serviceTypes and "QUERY" in serviceTypes and "COLUMN" in serviceTypes
                    @providers.push endpointName
        return

    @onProviderChange = () =>
        @requests.setDataProvider @currentProvider
        if @currentProvider
            @getTableList()

    @getTableList = () =>
        $http.get(@requests.metaDataTableNames()).success (data) =>
            @tableList = data
        return

    @getMetaData = () =>
        $http.get(@requests.metaDataTable @currentTable).success (data) =>
            @tableMetaData = data
            @getData()
        return

    @getData = () =>
        @tableData = {}
        $http.get(@requests.dataTable @currentTable, @limit).success (data) =>
            @tableData = data
        return

    @selectTable = (table) ->
        @currentTable = table
        @getMetaData()
        return

    @selectField = (field) ->
        @currentField = field
        return

    @transposeData = () ->
        @isHeaderColumn = !@isHeaderColumn

    @getDataProviders()

    return
]
