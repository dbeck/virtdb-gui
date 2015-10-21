app = require './virtdb-app.js'
module.exports = app.controller 'ConfigController',
class ConfigController

    constructor: ($http, $scope, $rootScope) ->
        @$http = $http
        @$scope = $scope
        @$rootScope = $rootScope
        @configs = []
        @setupWatches()

    setupWatches: () =>
        @$rootScope.$watch "selectedComponent", () =>
            @$scope.selectedComponent = @$rootScope.selectedComponent
            @requestConfig

    requestConfig: () =>
        @$http.get("/api/get_config/" + @$scope.selectedComponent).succes (data) =>
            @$scope.componentConfig = data
