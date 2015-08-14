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
                ErrorService.errorHappened status, "Failed to get list of enabled features. (#{response})"

        getSettings: (onSuccess) ->
            $http.get @address + "/api/settings"
            .success(onSuccess)
            .error (response, status) ->
                ErrorService.errorHappened status, "Failed to get configuration. (#{response})"

        getCertificates: (onSuccess) ->
            $http.get @address + "/api/certificate"
                .success(onSuccess)
                .error (response, status) ->
                    ErrorService.errorHappened status, "Failed to get list of certificates. (#{response})"

        getMonitoring: (onSuccess) ->
            $http.get @address + "/api/monitoring"
                .success(onSuccess)
                .error (response, status) ->
                    ErrorService.errorHappened status, "Failed to get monitoring information. (#{response})"

        approveCertificate: (authCode, component, onSuccess) ->
            data =
                authCode: authCode
            $http.put @address + "/api/certificate/#{encodeURIComponent(component.ComponentName)}", data
                .success(onSuccess)
                .error (response, status) ->
                    ErrorService.errorHappened status, "Failed to approve certificate of #{component.ComponentName}. (#{response})"

        removeCertificate: (component, onSuccess) ->
            $http.delete(@address + "/api/certificate/#{encodeURIComponent(component.ComponentName)}/#{encodeURIComponent(component.PublicKey)}")
                .success(onSuccess)
                .error (response, status) =>
                    ErrorService.errorHappened status, "Failed to remove certificate of #{component.ComponentName}. (#{response})"

        getEndpoints: (onSuccess, onError) =>
            $http.get(@address + "/api/endpoints").success(onSuccess)
            .error(
                (response, status) =>
                    ErrorService.errorHappened status, "Failed to get component list. (#{response})"
            )

        getDataProviders: (onSuccess) =>
            $http.get(@address + "/api/data_provider/list").success(onSuccess)
            .error( (response, status) =>
                ErrorService.errorHappened status, "Failed to get data provider list. (#{response})"
                onSuccess []
            )

        getAuthenticationMethods: (onSuccess) =>
            $http.get(@address + "/api/authmethods").success(onSuccess)
            .error( (response, status) =>
                ErrorService.errorHappened status, "Failed to get authentication methods. (#{response})"
                onSuccess []
            )

        getCurrentUser: (onSuccess) =>
            $http.get(@address + "/api/user").success(onSuccess)
            .error( (response, status) =>
                ErrorService.errorHappened status, "Failed to get user information. (#{response})"
                onSuccess null
            )

        login: (username, password, done) =>
            data =
                username: username
                password: password
            $http.post(@address + "/login", data).success(done)
            .error( (response, status) =>
                ErrorService.errorHappened status, "Failed to loging user #{data.username}"
            )

        getUserList: (onSuccess) =>
            $http.get(@address + "/api/user/list").success(onSuccess)
            .error( (response, status) =>
                ErrorService.errorHappened status, "Failed to get user list. (#{response})"
                onSuccess []
            )

        deleteUser: (data, done) =>
            $http.delete(@address + "/api/user/" + data).success(done)
            .error( (response, status) =>
                ErrorService.errorHappened status, "Failed to delete user #{data.name}. (#{response})"
                done(new Error(response))
            )

        updateUser: (data, done) =>
            $http.put(@address + "/api/user/" + data.name, data).success(done)
            .error( (response, status) =>
                ErrorService.errorHappened status, "Failed to update user information of #{data.name}. (#{response})"
            )

        createUser: (data, done) =>
            $http.post(@address + "/api/user", data).success(done)
            .error( (response, status) =>
                ErrorService.errorHappened status, "Failed to create user #{data.name}. (#{response})"
                done(new Error(response))
            )

        getTableList: (data, onSuccess, onError) =>
            data.id = generateRequestId()

            $http.post(@address + "/api/data_provider/table_list", data, {timeout: @createCanceler data.id})
            .success( (response) =>
                onSuccess response.data
            )
            .error( (response, status) =>
                if status not in [0, 503]
                    ErrorService.errorHappened status, "Failed to get table list for #{data.provider}. (#{response})"
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
                ErrorService.errorHappened status, "Failed to get table information. (#{response})"
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
                ErrorService.errorHappened status, "Failed to get table data. (#{response})"
                onSuccess []
            )
            return data.id

        getConfig: (data, onSuccess) =>
            $http.get @address + '/api/get_config/' + data.selectedComponent
                .success onSuccess
                .error (response, status) ->
                    ErrorService.errorHappened status, "Failed to get configuration of component: #{data.selectedComponent} (#{response})"

        getCredential: (data, onSuccess) =>
            $http.get @address + '/api/get_credential/' + data.selectedComponent
                .success onSuccess
                .error (response, status) ->
                    ErrorService.errorHappened status, "Failed to get credential template of component: #{data.selectedComponent} (#{response})"

        setCredential: (data, onSuccess) =>
            $http.post @address + '/api/set_credential/' + data.selectedComponent, data.credentials
                .success onSuccess
                .error (response, status) ->
                    ErrorService.errorHappened status, "Failed to set credential: #{data.selectedComponent} (#{response})"

        setConfig: (data, onSuccess, onError) =>
            $http.post @address + '/api/set_config/' + data.selectedComponent, data.componentConfig
                .success onSuccess
                .error (response, status) ->
                    ErrorService.errorHappened status, "Failed to set configuration of component: #{data.selectedComponent}  (#{response})"
                    onError(response, status)

        sendDBConfig: (data, onSuccess) =>
            $http.post(@address + "/api/db_config/tables", data)
            .success(onSuccess)
            .error( (response, status) =>
                    ErrorService.errorHappened status, "Failed to add table: #{data.table} (#{response})"
            )

        deleteDBConfig: (data, onSuccess) =>
            $http.delete(@address + "/api/db_config/tables", {params: data})
            .success(onSuccess)
            .error( (response, status) =>
                    ErrorService.errorHappened status, "Failed to delete table: #{data.table} (#{response})"
            )

        getDBConfig: (data, onSuccess) =>
            $http.get(@address + "/api/db_config/tables", {params: data})
            .success(onSuccess)
            .error( (response, status) =>
                ErrorService.errorHappened status, "Failed to retreive list of added tables from host database for: #{data.provider} (#{response})"
                onSuccess []
            )

        getDBUsers: (onSuccess) =>
            $http.get @address + "/api/db_config/users"
            .success(onSuccess)
            .error( (response, status) =>
                ErrorService.errorHappened status, "Failed to retreive list of database users from host database: (#{response})"
                onSuccess null
            )

        addUserToDB: (data, onSuccess) =>
            $http.post @address + "/api/db_config/users", data
            .success(onSuccess)
            .error( (response, status) =>
                ErrorService.errorHappened status, "Failed to add user to the host database: (#{response})"
                onSuccess null
            )

        getLogs: (data, onDiagMessage) =>
            $http.post(@address + "/api/get_diag/", data)
            .success(onDiagMessage)
            .error( (response, status) =>
                ErrorService.errorHappened status, "Failed to get log messages. (#{response})"
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
