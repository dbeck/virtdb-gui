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
        .when '/config', {
            templateUrl : '../pages/configuration.html',
            controller  : 'ConfigurationController',
            controllerAs: 'cfg',
        }
    return

app.controller 'DiagnosticsController', ($scope) ->
    @endpoint = 'diagnostics'
    return

app.controller 'EndpointController', ['$scope', '$http', ($scope, $http) ->
    @endpoints = ''

    $http.get("/api/endpoints").success (data) =>
        @endpoints = data
    return
]

app.controller 'ConfigurationController', ['$scope', '$http', ($scope, $http) ->

    @config = {}

    @setConfig = () =>
        $http.post("/api/set_app_config", @config)

    @getConfig = () =>
        $http.get("/api/get_app_config").success (data) =>
            @config = data

    @getConfig()

    return

]
