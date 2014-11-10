app = angular.module 'virtdb'
app.controller 'StatusController',
    class StatusController

        @REQUEST_INTERVAL = 2000
        @DONE_OBSOLETE_TIME = 10 * 60 * 1000
        @DONE_OBSOLETE_CHECK_INTERVAL = 10 * 1000
        statusMessages: null
        lastStatusRequestTime: null

        constructor: (@$rootScope, @$scope, @$http, @$interval, @ServerConnector) ->
            @statusMessages = []
            @lastStatusRequestTime = 0
            @startTimers()

        startTimers: () =>
            @requestStatuses()
            @$interval @requestStatuses, DiagnosticsController.REQUEST_INTERVAL
            @cleanObsoleteDones()
            @$interval @cleanObsoleteDones, StatusController.DONE_OBSOLETE_CHECK_INTERVAL

        cleanObsoleteDones: () =>
            now = new Date
            copyStatusMessages = @statusMessages.slice 0
            if copyStatusMessages.length > 0
                for i in [0..copyStatusMessages.length - 1]
                    status = copyStatusMessages[i]
                    isObsolete =  now - status.time > StatusController.DONE_OBSOLETE_TIME
                    containsDone = status.status.indexOf("DONE") > -1
                    if containsDone and isObsolete
                        index = @statusMessages.indexOf status
                        @statusMessages.splice index, 1

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
                    log.time = entry.time
                    parts = []
                    for part in entry.parts
                        log[part.name] = part.value
                    @placeStatusMessage log
                    @cleanObsoleteDones()

        placeStatusMessage: (newStatus) =>
            if @statusMessages.length isnt 0
                for i in [0..@statusMessages.length - 1]
                    status = @statusMessages[i]
                    if status.table_name == newStatus.table_name and status.component == newStatus.component and status.query_id == newStatus.query_id
                        @statusMessages.splice i, 1
            @statusMessages.push newStatus
