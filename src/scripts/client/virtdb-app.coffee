
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
    @selectedProvider = ''
    @providers = []

    @metaData = []
    @data = []
    @currentTable = ''
    @currentField = ''
    _this = this

    @onProviderChange = () ->
        if @selectedProvider
            @getMetaData()

    @getMetaData = () ->
        $http.get("/api/data_providers/" + @selectedProvider + "/meta_data").success (data) ->
            _this.metaData = data
        return

    @getDataProviders = () ->
        $http.get("/api/endpoints").success (data) ->
            services = {}
            for endpoint in data
                services[endpoint.Name] = [] unless services.hasOwnProperty endpoint.Name
                services[endpoint.Name].push(endpoint.SvcType)
            for endpointName, serviceTypes of services
                if "META_DATA" in serviceTypes and "QUERY" in serviceTypes and "COLUMN" in serviceTypes
                    _this.providers.push endpointName
        return

    @selectTable = (table) ->
        _this.currentTable = table
        return

    @selectField = (field) ->
        _this.currentField = field
        return

    @getSelectedTableFields = () ->
        return table.Fields for table in _this.metaData.Tables when table.Names is _this.selectedTable

    @selectedTableFilter = (table) ->
            return table.Name is _this.selectedTable

    @getDataProviders()

    return
]

app.controller 'DiagnosticsController', ($scope) ->
    @endpoint = 'diagnostics'
    return

app.controller 'EndpointController', ['$scope', '$http', ($scope, $http) ->
    @endpoints = ''
    _this = this
    $http.get("/api/endpoints").success (data) ->
        _this.endpoints = data
    return
]
