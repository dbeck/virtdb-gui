
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
    @endpoint = 'csv-provider'
    @metaData = []
    @data = []
    _this = this

    @getMetaData = () ->
        $http.get("/api/data_providers/" + _this.endpoint + "/meta_data").success (data) ->
            _this.metaData = data
        return
    @getMetaData()
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
