
app = angular.module 'virtdb', ['ngRoute']
app.config ($routeProvider) ->
    $routeProvider
        .when '/data-providers', {
            templateUrl : '../pages/data-provider.html',
            controller  : 'DataProviderController',
            controllerAs: 'dataProvider',
        }
        .when '/diagnostics', {
            templateUrl : '../pages/diagnostics.html',
            controller  : 'DiagnosticsController',
            controllerAs: 'diag',
        }
        .when '/endpoints', {
            templateUrl : '../pages/endpoints.html',
            controller  : 'EndpointController',
            controllerAs: 'endpoint',
        }
    return

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
            @tableMetaData = data.Tables[0]
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

    @getDataProviders()

    return
]

app.controller 'DiagnosticsController', ($scope) ->
    @endpoint = 'diagnostics'
    return

app.controller 'EndpointController', ['$scope', '$http', ($scope, $http) ->
    @endpoints = ''
    $http.get("/api/endpoints").success (data) =>
        @endpoints = data
    return
]
