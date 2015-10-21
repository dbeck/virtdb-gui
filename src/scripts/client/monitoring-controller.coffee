app = require './virtdb-app.js'

ServerConnector = require './server-connector.js'

app.filter 'isOK', ->
    return (component) ->
        if component.OK
            return 'OK'
        else
            message = 'DOWN'
            for event in component.Events
                if event.Type is 'SET_STATE' and event.SubType is 'NOT_INITIALIZED'
                    message = 'NOT INITIALIZED'
            return message

app.filter 'subType', ->
    return (type) ->
        switch type
            when 'CLEAR' then 'OK'
            else type

app.filter 'eventType', ->
    return (event) ->
        switch event.Type
            when 'COMPONENT_ERROR'
                if event.SubType is 'CLEAR' then 'STATUS' else 'COMPONENT ERROR'
            when 'REQUEST_ERROR' then 'REQUEST ERROR'
            when 'SET_STATE' then 'STATUS'
            else 'STATUS'

module.exports = app.controller 'MonitoringController',
    ($scope, $rootScope, $interval, ServerConnector) ->
        getMonitoring = ->
            ServerConnector.getMonitoring (components) ->
                $scope.statuses = components
        # $rootScope.pullMonitoringInterval ?= $interval getMonitoring, 5000
        getMonitoring()
