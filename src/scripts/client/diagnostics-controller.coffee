app = angular.module 'virtdb'
dgController = app.controller 'DiagnosticsController',
    class DiagnosticsController

        @REQUEST_INTERVAL = 2000
        logEntries: null
        lastLogRequestTime: null
        @MAX_DISPLAYED_DIAG_MSG = 2000
        requestIntervalPromise: null

        constructor: ($rootScope, $scope, $http, $interval, ServerConnector) ->
            @$rootScope = $rootScope
            @$scope = $scope
            @$http = $http
            @$interval = $interval
            @ServerConnector = ServerConnector
            @logEntries = []
            @lastLogRequestTime = 0
            @startLogReceiving()
            @$scope.$on '$destroy', () =>
                if @requestIntervalPromise?
                    @$interval.cancel @requestIntervalPromise

        startLogReceiving: () =>
            @requestLogs()
            @requestIntervalPromise = @$interval @requestLogs, DiagnosticsController.REQUEST_INTERVAL

        requestLogs: () =>
            data =
                from: @lastLogRequestTime
                levels: ["VIRTDB_INFO", "VIRTDB_ERROR", "VIRTDB_SIMPLE_TRACE"]
            @ServerConnector.getLogs(data, @onDiagMessage)

        onDiagMessage: (entries) =>
            @lastLogRequestTime = (new Date).getTime()
            for entry in entries
                log = {}
                log.component = entry.process.name
                log.time = entry.time
                log.level = entry.level.split("_")[1]
                log.file = entry.location.file
                log.line = entry.location.line
                log.function = entry.location.function
                parts = []
                for part in entry.parts
                    if not part.value?
                        parts.push part.name
                    else if not part.name?
                        parts.push part.value
                    else
                        parts.push part.name + "=" + part.value
                log.message = parts.join ", "
                @logEntries.push log
                if @logEntries.length > DiagnosticsController.MAX_DISPLAYED_DIAG_MSG
                    @logEntries.splice 0,1

dgController.directive 'diagTable', diagTableDirective
