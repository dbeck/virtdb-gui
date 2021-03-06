app = angular.module 'virtdb', ['ngRoute', 'react']

app.config ($routeProvider) ->
    $routeProvider
        .when '/',
            templateUrl: '../pages/data-provider.html'
            controller: 'DataProviderController'
            controllerAs: 'dataProvider'
        .when '/data-providers',
            templateUrl: '../pages/data-provider.html'
            controller: 'DataProviderController'
            controllerAs: 'dataProvider'
        .when '/component-config',
            templateUrl: '../pages/endpoints.html'
            controller: 'EndpointController'
            controllerAs: 'endpointController'
        .when '/diag',
            templateUrl: '../pages/diag.html'
            controller: 'DiagnosticsController'
            controllerAs: 'diag'
        .when '/status',
            templateUrl: '../pages/status.html'
            controller: 'StatusController'
            controllerAs: 'statusController'
        .when '/monitoring',
            templateUrl: '../pages/monitoring.html'
            controller: 'MonitoringController'
        .when '/admin',
            templateUrl: '../pages/admin.html'
            controller: 'AdminController'
        .when '/users',
            templateUrl: '../pages/users.html'
            controller: 'UserController'
    return

app.controller 'FeatureController', ($scope, $rootScope, ServerConnector) ->
    ServerConnector.getFeatures (data) ->
        $rootScope.Features = data
    ServerConnector.getSettings (data) ->
        $rootScope.Settings = data

module.exports = app
