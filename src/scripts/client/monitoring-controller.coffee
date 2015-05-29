app = require './virtdb-app.js'

ServerConnector = require './server-connector.js'

app.filter 'isOK', ->
    return (input) ->
        return if input then 'OK' else 'NOT OK'

module.exports = app.controller 'MonitoringController',
    ($scope, $rootScope, $interval, ServerConnector) ->
        getMonitoring = ->
            ServerConnector.getMonitoring (components) ->
                $scope.statuses = components
                for component in components
                    console.dir component
        # $rootScope.pullMonitoringInterval ?= $interval getMonitoring, 5000
        getMonitoring()
