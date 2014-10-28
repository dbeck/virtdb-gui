app = angular.module 'virtdb'
app.factory 'ServerConnector', ['$http', 'ErrorService', ($http, ErrorService) ->
    new class ServerConnector

        constructor: () ->
            @address = ""
            @obsoleteIdList = []

        getEndpoints: (onSuccess, onError) =>
            $http.get(@address + "/api/endpoints").success(onSuccess)
            .error(
                () =>
                    ErrorService.errorHappened "Couldn't get endpoint list from server!"
            )

        getTableList: (data, onSuccess) =>
            data.id = generateRequestId()
            $http.post(@address + "/api/data_provider/table_list", data)
            .success( (response) =>
                if @checkResponseId(response.id)
                    onSuccess response.data
                else
                    console.warn "Table list request outdated. id=" + response.id
            )
            .error( () =>
                ErrorService.errorHappened "Couldn't get table list! " + JSON.stringify data
                console.error data
            )
            return data.id

        getMetaData: (data, onSuccess) =>
            data.id = generateRequestId()
            $http.post(@address + "/api/data_provider/meta_data", data)
            .success( (response) =>
                if @checkResponseId(response.id)
                    onSuccess response.data
                else
                    console.warn "Meta data request outdated. id=" + response.id
            )
            .error( () =>
                ErrorService.errorHappened "Couldn't get meta data! " + JSON.stringify data
                console.error data
            )
            return data.id

        getData: (data, onSuccess) =>
            data.id = generateRequestId()
            $http.post(@address + "/api/data_provider/data", data)
            .success( (response) =>
                    if @checkResponseId(response.id)
                        onSuccess response.data
                    else
                        console.warn "Data request outdated. id=" + response.id
            )
            .error( () =>
                    ErrorService.errorHappened "Couldn't get data! "  + JSON.stringify data
                    console.error data
            )
            return data.id

        sendDBConfig: (data) =>
            $http.post(@address + "/api/db_config", data)
            .error( () =>
                    ErrorService.errorHappened "Couldn't add table to db config! "  + JSON.stringify data
                    console.error data
            )

        generateRequestId = () =>
            return Math.floor(Math.random() * 1000000) + 1

        checkResponseId: (id) =>
            index = @obsoleteIdList.indexOf(id)
            if index > -1
                @obsoleteIdList.splice(index, 1);
                return false
            return true

        obsoleteId: (id) =>
            @obsoleteIdList.push id

]