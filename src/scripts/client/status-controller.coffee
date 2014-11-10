app = angular.module 'virtdb'
app.controller 'StatusController',
    class StatusController

        @REQUEST_INTERVAL = 2000
        statusMessages: null
        lastStatusRequestTime: null

        constructor: (@$rootScope, @$scope, @$http, @$interval, @ServerConnector) ->
            @statusMessages = []
            @lastStatusRequestTime = 0
            @startStatusReceiving()

        startStatusReceiving: () =>
            @requestStatuses()
            @$interval @requestStatuses, DiagnosticsController.REQUEST_INTERVAL

        requestStatuses: () =>
            data =
                from: @lastStatusRequestTime
                levels: ["VIRTDB_STATUS"]
            @ServerConnector.getLogs(data, @onStatusMessage)

        onStatusMessage: (entries) =>
            @lastStatusRequestTime = (new Date).getTime()
            if entries.length isnt 0
                for i in [entries.length - 1..0]
                    entry = entries[i]
                    log = {}
                    log.component = entry.process.name
                    log.time = (new Date (entry.time)).toLocaleString()
                    parts = []
                    for part in entry.parts
                        log[part.name] = part.value
                    @placeStatusMessage log

        placeStatusMessage: (newStatus) =>
            if @statusMessages.length isnt 0
                for i in [0..@statusMessages.length - 1]
                    status = @statusMessages[i]
                    if status.table_name == newStatus.table_name and status.component == newStatus.component and status.query_id == newStatus.query_id
                        @statusMessages.splice i, 1
            @statusMessages.push newStatus
