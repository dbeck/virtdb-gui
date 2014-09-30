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

app.controller 'DiagnosticsController', ($scope) ->
    @endpoint = 'diagnostics'
    return

app.controller 'EndpointController', ['$scope', '$http', ($scope, $http) ->
    @endpoints = ''
    $http.get("/api/endpoints").success (data) =>
        @endpoints = data
    return
]
