app = angular.module 'virtdb', ['ngRoute', 'react']

app.config ($routeProvider) ->
    $routeProvider
        .when '/', {
            templateUrl : '../pages/data-provider.html',
            controller  : 'DataProviderController',
            controllerAs: 'dataProvider',
        }
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

module.exports = app
