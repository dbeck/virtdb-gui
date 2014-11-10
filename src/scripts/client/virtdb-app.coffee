app = angular.module 'virtdb', ['ngRoute']

app.config ($routeProvider) ->
    $routeProvider
        .when '/data-providers', {
            templateUrl : '../pages/data-provider.html',
            controller  : 'DataProviderController',
            controllerAs: 'dataProvider',
        }
        .when '/component-config', {
            templateUrl : '../pages/endpoints.html',
            controller  : 'EndpointController',
            controllerAs: 'endpointController',
        }
        .when '/config', {
            templateUrl : '../pages/configuration.html',
            controller  : 'ConfigurationController',
            controllerAs: 'cfg',
        }
        .when '/diag', {
            templateUrl : '../pages/diag.html',
            controller  : 'DiagnosticsController',
            controllerAs: 'diag',
        }
        .when '/status', {
            templateUrl : '../pages/status.html',
            controller  : 'StatusController',
            controllerAs  : 'statusController',
        }
    return

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
