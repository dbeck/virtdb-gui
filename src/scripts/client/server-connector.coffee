app = angular.module 'virtdb'
app.factory 'ServerConnector', ['$http', 'ErrorService', '$q', ($http, ErrorService, $q) ->
    new class ServerConnector

        constructor: () ->
            @address = ""
            @pendingRequestIds = {}

        getEndpoints: (onSuccess, onError) =>
            $http.get(@address + "/api/endpoints").success(onSuccess)
            .error(
                (response, status) =>
                    ErrorService.errorHappened "Couldn't get endpoint list from server! response: " + response
            )

        getTableList: (data, onSuccess) =>
            data.id = generateRequestId()

            $http.post(@address + "/api/data_provider/table_list", data, {timeout: @createCanceler data.id})
            .success( (response) =>
                onSuccess response.data
            )
            .error( (response, status) =>
                ErrorService.errorHappened "Couldn't get table list! " + JSON.stringify(data) + " response: " + response
                onSuccess null
            )
            return data.id

        getMetaData: (data, onSuccess) =>
            data.id = generateRequestId()
            $http.post(@address + "/api/data_provider/meta_data", data, {timeout: @createCanceler data.id})
            .success( (response) =>
                onSuccess response.data
            )
            .error( (response, status) =>
                ErrorService.errorHappened "Couldn't get meta data! " + JSON.stringify(data) + " response: " + response
                onSuccess []
            )
            return data.id

        getData: (data, onSuccess) =>
            data.id = generateRequestId()
            $http.post(@address + "/api/data_provider/data", data, {timeout: @createCanceler data.id})
            .success( (response) =>
                onSuccess response.data
            )
            .error( (response, status) =>
                ErrorService.errorHappened "Couldn't get data! " + JSON.stringify(data) + " response: " + response
                onSuccess []
            )
            return data.id

        sendDBConfig: (data, onSuccess) =>
            $http.post(@address + "/api/db_config/add", data)
            .success(onSuccess)
            .error( (response, status) =>
                    ErrorService.errorHappened "Couldn't add table to db config! " + JSON.stringify(data) + " response: " + response
            )

        getDBConfig: (data, onSuccess) =>
            $http.post(@address + "/api/db_config/get", data)
            .success(onSuccess)
            .error( (response, status) =>
                ErrorService.errorHappened "Couldn't get table list from db config! " + JSON.stringify(data) + " response: " + response
                onSuccess []
            )

        getLogs: (data, onDiagMessage) =>
            $http.post(@address + "/api/get_diag/", data)
            .success(onDiagMessage)
            .error( (response, status) =>
                ErrorService.errorHappened "Couldn't get diag messages! " + JSON.stringify(data) + " response: " + response
                onDiagMessage []
            )

        generateRequestId = () =>
            return Math.floor(Math.random() * 1000000) + 1

        cancelRequest: (id) =>
            canceler = @pendingRequestIds[id]
            if canceler?
                console.warn "Cancel request: " + id
                canceler.resolve "Request outdated"
                delete @pendingRequestIds[id]

        createCanceler: (id) =>
            canceller = $q.defer()
            @pendingRequestIds[id] = canceller
            return canceller.promise

]
