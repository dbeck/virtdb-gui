app = angular.module 'virtdb'
app.controller 'DataProviderController',
    class DataProviderController

        @TABLE_LIST_DISPLAY_COUNT = 10
        @DATA_LIMIT = 20

        constructor: (@$rootScope, @$scope, @$http, @ServerConnector) ->

            @selectedTables = []
            @providers = []
            @requestIds = {}

            @tableMetaData = null
            @tableList = null

            @isHeaderColumn = false
            @tableListPosition = 0
            @isMoreTable = true

            @getDataProviders()

        getDataProviders: () =>
            @ServerConnector.getEndpoints(
                (data) =>
                    services = {}
                    for endpoint in data
                        services[endpoint.Name] ?= []
                        services[endpoint.Name].push(endpoint.SvcType)
                    for endpointName, serviceTypes of services
                        if "META_DATA" in serviceTypes and "QUERY" in serviceTypes and "COLUMN" in serviceTypes
                            @providers.push endpointName
                    @selectProvider(@providers[0])
            )
            return

        selectProvider: (provider) =>
            if provider is @$rootScope.provider
                return
            @$rootScope.provider = provider
            @resetProviderLevelView()
            @requestTableList()

        resetTableLevelView: () =>
            @tableData = null
            @$scope.dataHeader = []
            @$scope.dataRows = []
            @$scope.meta = null
            @$scope.fieldDescription = null
            @$scope.field = null

        resetProviderLevelView: () =>
            @resetTableLevelView()

            @tableList = []
            @tableListPosition = 0

            @$scope.table = null
            @$scope.search = ""
            @$scope.tableListFrom = 0
            @$scope.tableListTo = 0
            @$scope.tableListCount = 0

        requestTableList: () =>
            @tableList = []
            requestData =
                search: @$scope.search
                provider: @$rootScope.provider
                from: @tableListPosition + 1
                to: @tableListPosition + DataProviderController.TABLE_LIST_DISPLAY_COUNT
            @ServerConnector.obsoleteId @requestIds["tableList"]
            @requestIds["tableList"] = @ServerConnector.getTableList(requestData, @onTableList)
            return

        onTableList: (data) =>
            @$scope.tableListCount = data.count
            if data.count > 0
                @$scope.tableListFrom = data.from + 1
                @$scope.tableListTo = data.to + 1
            else
                @$scope.tableListFrom = data.from
                @$scope.tableListTo = data.to

            if data.results.length is 0
                @isMoreTable = false
                return

            @isMoreTable = data.results.length is DataProviderController.TABLE_LIST_DISPLAY_COUNT
            @tableList = data.results

        requestMetaData: () =>
            requestData =
                provider: @$rootScope.provider
                table: @$scope.table
            @ServerConnector.obsoleteId @requestIds["metaData"]
            @requestIds["metaData"] = @ServerConnector.getMetaData(requestData, @onMetaData)
            return

        onMetaData: (data) =>
            @tableMetaData = data
            @$scope.meta = data
            @requestData()

        requestData: () =>
            requestData =
                provider: @$rootScope.provider
                table: @$scope.table
                count: DataProviderController.DATA_LIMIT
            @ServerConnector.obsoleteId @requestIds["data"]
            @requestIds["data"] = @ServerConnector.getData(requestData, @onData)
            return

        onData: (data) =>
            if data.length is 0
                return
            dataRows = []
            headerRow = []
            for column in data
                headerRow.push column.Name
            for i in [0..data[0].Data.length-1]
                row = []
                for column in data
                    row.push column.Data[i]
                dataRows.push row
            @$scope.dataHeader = headerRow
            @$scope.dataRows = dataRows


        selectTable: (table) =>
            @$scope.table = table
            @resetTableLevelView()
            @requestMetaData()
            return

        selectField: (field) =>
            @$scope.field = field
            @$scope.metaData = (fieldMeta for fieldMeta in @tableMetaData.Fields when fieldMeta.Name is field)[0]
            return

        transposeData: () =>
            @isHeaderColumn = !@isHeaderColumn

        getNextTables: () =>
            if @isMoreTable
                @tableListPosition = @tableListPosition + DataProviderController.TABLE_LIST_DISPLAY_COUNT
                @requestTableList()

        getPreviousTables: () =>
            if @tableListPosition isnt 0
                @tableListPosition = @tableListPosition - DataProviderController.TABLE_LIST_DISPLAY_COUNT
                @requestTableList()

        searchTableNames: () =>
            @tableListPosition = 0
            @requestTableList()

        selectTableToDBConfig: (table) =>
            if table not in @selectedTables
                @selectedTables.push table
            else
                @selectedTables.splice @selectedTables.indexOf table, 1

        addTablesToDBConfig: () =>
            for table in @selectedTables
                data =
                    table: table
                    provider: @$scope.provider
                @ServerConnector.sendDBConfig(data)
            return
