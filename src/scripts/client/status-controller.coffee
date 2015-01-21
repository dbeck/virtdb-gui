app = angular.module 'virtdb'
app.controller 'StatusController',
    class StatusController

        @REQUEST_INTERVAL = 2000
        @DONE_OBSOLETE_TIME = 10 * 60 * 1000
        @DONE_OBSOLETE_CHECK_INTERVAL = 10 * 1000
        statusMessages: null
        incomingMessages: null
        lastStatusRequestTime: null
        requestPromise: null
        processPromise: null

        constructor: (@$rootScope, @$scope, @$http, @$interval, @ServerConnector) ->
            @statusMessages = []
            @incomingMessages = []
            @lastStatusRequestTime = 0
            @startTimers()
            @$scope.$on "$destroy", () =>
                if @requestPromise?
                    @$interval.cancel @requestPromise
                if @processPromise?
                    @$interval.cancel @processPromise

        startTimers: () =>
            @processPromise = @$interval @processIncomingMessages, 500
            @requestStatuses()
            @requestPromise = @$interval @requestStatuses, DiagnosticsController.REQUEST_INTERVAL

        cleanObsoleteDones: () =>
            copyStatusMessages = @statusMessages.slice 0
            if copyStatusMessages.length > 0
                for i in [0..copyStatusMessages.length - 1]
                    status = copyStatusMessages[i]
                    containsDone = status?.status?.indexOf("DONE") > -1
                    if containsDone and @isStatusObsolete(status)
                        index = @statusMessages.indexOf status
                        @statusMessages.splice index, 1

        isStatusObsolete: (status) =>
            now = new Date
            return now - status?.time > StatusController.DONE_OBSOLETE_TIME

        requestStatuses: () =>
            data =
                from: @lastStatusRequestTime
                levels: ["VIRTDB_STATUS"]
            @ServerConnector.getLogs(data, @onStatusMessage)

        onStatusMessage: (entries) =>
            @lastStatusRequestTime = (new Date).getTime()
            if entries.length isnt 0
                for entry in entries
                    log = {}
                    log.component = entry.process.name
                    log.time = entry.time
                    parts = []
                    for part in entry.parts
                        log[part.name] = part.value
                    @incomingMessages.push log

        processIncomingMessages: () =>
            @cleanObsoleteDones()
            while @incomingMessages.length > 0
                msg = @incomingMessages.shift()
                if not @isStatusObsolete msg
                    @placeStatusMessage msg

        placeStatusMessage: (newStatus) =>
            if @statusMessages.length is 0
                @statusMessages.push newStatus
                return

            for i in [0..@statusMessages.length - 1]
                status = @statusMessages[i]
                if status?.table_name is newStatus?.table_name and status?.component is newStatus?.component and status?.query_id is newStatus?.query_id
                    @statusMessages[i] = newStatus
                    return
            @statusMessages.push newStatus
