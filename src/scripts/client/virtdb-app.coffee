
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
    @currentProvider = ''
    @providers = []

    @metaData = []
    @data = {}
    @currentTable = {}
    @currentField = ''
    @limit = 10
    @rowIndexes = [0..@limit-1]

    @onProviderChange = () ->
        if @currentProvider
            @getMetaData()

    @getMetaData = () =>
        $http.get("/api/data_providers/" + @currentProvider + "/meta_data").success (data) =>
            @metaData = data
        return

    @getData = () =>
        fields = (field.Name for field in @currentTable.Fields).join()
        $http.get(
            "/api/data_providers/" + @currentProvider + "/data/table/" + @currentTable.Name + "/fields/" + fields + "/count/" + @limit
            ).success (data) =>
                @data = data
        return

    @getDataProviders = () ->
        $http.get("/api/endpoints").success (data) =>
            services = {}
            for endpoint in data
                services[endpoint.Name] ?= []
                services[endpoint.Name].push(endpoint.SvcType)
            for endpointName, serviceTypes of services
                if "META_DATA" in serviceTypes and "QUERY" in serviceTypes and "COLUMN" in serviceTypes
                    @providers.push endpointName
        return

    @selectTable = (selectedTable) ->
        @currentTable = (table for table in @metaData.Tables when table.Name is selectedTable)[0]
        @getData()
        return

    @selectField = (field) ->
        @currentField = field
        return

    @selectedTableFilter = (table) =>
        return table.Name is @selectedTable

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
