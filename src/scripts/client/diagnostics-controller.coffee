app = angular.module 'virtdb'
app.controller 'DiagnosticsController',
    class DiagnosticsController

        @REQUEST_INTERVAL = 2000
        logEntries: null
        lastLogRequestTime: null
        @MAX_DISPLAYED_DIAG_MSG = 2000

        constructor: (@$rootScope, @$scope, @$http, @$interval, @ServerConnector) ->
            @logEntries = []
            @lastLogRequestTime = 0
            @startLogReceiving()

        startLogReceiving: () =>
            @requestLogs()
            @$interval @requestLogs, DiagnosticsController.REQUEST_INTERVAL

        requestLogs: () =>
            data =
                from: @lastLogRequestTime
                levels: ["VIRTDB_INFO", "VIRTDB_ERROR"]
            @ServerConnector.getLogs(data, @onDiagMessage)

        onDiagMessage: (entries) =>
            @lastLogRequestTime = (new Date).getTime()
            for entry in entries
                log = {}
                log.component = entry.process.name
                log.time = (new Date (entry.time)).toLocaleString()
                log.level = entry.level
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
