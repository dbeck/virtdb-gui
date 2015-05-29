app = require './virtdb-app.js'
module.exports = app.factory 'ServerConnector', ['$http', 'ErrorService', '$q', ($http, ErrorService, $q) ->
    new class ServerConnector

        constructor: () ->
            @address = ""
            @pendingRequestIds = {}

        getFeatures: (onSuccess) ->
            $http.get @address + "/api/features"
            .success(onSuccess)
            .error (response, status) ->
                ErrorService.errorHappened status, "Couldn't get feature list.", status

        getCertificates: (onSuccess) ->
            $http.get @address + "/api/certificate"
                .success(onSuccess)
                .error (response, status) ->
                    ErrorService.errorHappened status, "Couldn't get certificate list.", status

        getMonitoring: (onSuccess) ->
            $http.get @address + "/api/monitoring"
                .success(onSuccess)
                .error (response, status) ->
                    ErrorService.errorHappened status, "Couldn't get monitoring info", status


        approveCertificate: (authCode, component, onSuccess) ->
            data =
                authCode: authCode
            $http.put @address + "/api/certificate/#{encodeURIComponent(component.ComponentName)}", data
                .success(onSuccess)
                .error (response, status) ->
                    ErrorService.errorHappened status, "Couldn't approve certificate: #{component.ComponentName}", status

        removeCertificate: (component, onSuccess) ->
            data =
                publicKey: component.PublicKey
            $http.delete(@address + "/api/certificate/#{encodeURIComponent(component.ComponentName)}")
                .success(onSuccess)
                .error (response, status) =>
                        ErrorService.errorHappened status, "Couldn't remove certificate: #{component.ComponentName}", status

        getEndpoints: (onSuccess, onError) =>
            $http.get(@address + "/api/endpoints").success(onSuccess)
            .error(
                (response, status) =>
                    ErrorService.errorHappened status, "Couldn't get endpoint list from server! response: " + response
            )

        getDataProviders: (onSuccess) =>
            $http.get(@address + "/api/data_provider/list").success(onSuccess)
            .error( (response, status) =>
                ErrorService.errorHappened status, "Couldn't get data provider list! " + JSON.stringify(data) + " response: " + response
                onSuccess []
            )

        getAuthenticationMethods: (onSuccess) =>
            $http.get(@address + "/api/authmethods").success(onSuccess)
            .error( (response, status) =>
                ErrorService.errorHappened status, "Couldn't get authentication methods! " + JSON.stringify(data) + " response: " + response
                onSuccess []
            )

        getCurrentUser: (onSuccess) =>
            $http.get(@address + "/api/user").success(onSuccess)
            .error( (response, status) =>
                ErrorService.errorHappened status, "Couldn't get user info! " + JSON.stringify(data) + " response: " + response
                onSuccess []
            )

        getUserList: (onSuccess) =>
            $http.get(@address + "/api/user/list").success(onSuccess)
            .error( (response, status) =>
                ErrorService.errorHappened status, "Couldn't get user list! response: " + response
                onSuccess []
            )

        deleteUser: (data, done) =>
            $http.delete(@address + "/api/user/" + data).success(done)
            .error( (response, status) =>
                ErrorService.errorHappened status, "Couldn't delete user ! " + JSON.stringify(data) + " response: " + response
            )

        updateUser: (data, done) =>
            $http.put(@address + "/api/user/" + data.name, data).success(done)
            .error( (response, status) =>
                ErrorService.errorHappened status, "Couldn't update user! " + JSON.stringify(data) + " response: " + response
            )

        createUser: (data, done) =>
            $http.post(@address + "/api/user", data).success(done)
            .error( (response, status) =>
                ErrorService.errorHappened status, "Couldn't create user! " + JSON.stringify(data) + " response: " + response
            )

        getTableList: (data, onSuccess, onError) =>
            data.id = generateRequestId()

            $http.post(@address + "/api/data_provider/table_list", data, {timeout: @createCanceler data.id})
            .success( (response) =>
                onSuccess response.data
            )
            .error( (response, status) =>
                if status not in [0, 503]
                    ErrorService.errorHappened status, "Couldn't get table list! " + JSON.stringify(data) + " response: " + response + status
                onError response, status
            )
            return data.id

        getMetaData: (data, onSuccess) =>
            data.id = generateRequestId()
            $http.post(@address + "/api/data_provider/meta_data", data, {timeout: @createCanceler data.id})
            .success( (response) =>
                onSuccess response.data
            )
            .error( (response, status) =>
                ErrorService.errorHappened status, "Couldn't get meta data! " + JSON.stringify(data) + " response: " + response
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
                ErrorService.errorHappened status, "Couldn't get data! " + JSON.stringify(data) + " response: " + response
                onSuccess []
            )
            return data.id

        sendDBConfig: (data, onSuccess) =>
            $http.post(@address + "/api/db_config/add", data)
            .success(onSuccess)
            .error( (response, status) =>
                    ErrorService.errorHappened status, "Couldn't add table to db config! " + JSON.stringify(data) + " response: " + response
            )

        getDBConfig: (data, onSuccess) =>
            $http.post(@address + "/api/db_config/get", data)
            .success(onSuccess)
            .error( (response, status) =>
                ErrorService.errorHappened status, "Couldn't get table list from db config! " + JSON.stringify(data) + " response: " + response
                onSuccess []
            )

        getLogs: (data, onDiagMessage) =>
            $http.post(@address + "/api/get_diag/", data)
            .success(onDiagMessage)
            .error( (response, status) =>
                ErrorService.errorHappened status, "Couldn't get diag messages! " + JSON.stringify(data) + " response: " + response
                onDiagMessage []
            )

        generateRequestId = () =>
            return Math.floor(Math.random() * 1000000) + 1

        cancelRequest: (id) =>
            canceler = @pendingRequestIds[id]
            if canceler?
                canceler.resolve "Request outdated"
                delete @pendingRequestIds[id]

        createCanceler: (id) =>
            canceller = $q.defer()
            @pendingRequestIds[id] = canceller
            return canceller.promise

]
