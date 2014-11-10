app = angular.module 'virtdb'
app.controller 'DataProviderController',
    class DataProviderController

        @TABLE_LIST_DISPLAY_COUNT = 50
        @DATA_LIMIT = 20

        constructor: (@$rootScope, @$scope, @$http, @$timeout, @ServerConnector) ->

            @providers = []
            @requestIds = {}

            @tableMetaData = null
            @tableList = null

            @isHeaderColumn = false
            @tableListPosition = 0
            @isMoreTable = true

            @tablesToFilter = []

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
            @$scope.selectionCounter = 0
            @$scope.isAllTableSelected = false

        requestTableList: () =>
            @tableList = []
            requestData =
                tables: @tablesToFilter
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
            @tableList = []
            for tableName in data.results
                table =
                    name: tableName
                    selected: false
                    configured: false
                @tableList.push table

            @tableSelectionChanged()
            @requestConfiguredTables()

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
            firstColumn = data[0].Data
            if firstColumn.length > 0
                for i in [0..firstColumn.length-1]
                    row = []
                    for column in data
                        fieldValue = column.Data[i]
                        if fieldValue?
                            row.push fieldValue
                        else
                            row.push JSON.stringify(fieldValue)
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

        addTablesToDBConfig: () =>
            for table in @tableList
                if table.selected and not table.configured
                    data =
                        table: table.name
                        provider: @$scope.provider
                    table.selected = false
                    table.configured = true
                    @ServerConnector.sendDBConfig data, (data) =>
                        @$timeout(@requestConfiguredTables, 1000)
            return

        requestConfiguredTables: () =>
            data = provider: @$scope.provider
            @ServerConnector.getDBConfig(data, @onConfiguredTables)

        onConfiguredTables: (configuredTableList) =>
            for _table in @tableList
                _table.configured = false
                _table.selected = false
                for table in configuredTableList
                    if table is _table.name
                        _table.configured = true
                        _table.selected = true

        filterTableList: () =>
            @$scope.search = ""
            console.log @tablesToFilter
            @tableListPosition = 0
            @requestTableList()

        checkTableFilter: () =>
            @tablesToFilter = []
            for item in @$scope.tableListFilter.split("\n") when item.length > 0
                @tablesToFilter.push item

        selectAllTableChanged: () =>
            for table in @tableList when not table.configured
                table.selected = @$scope.isAllTableSelected
            @updateSelectionCounter()

        tableSelectionChanged: () =>
            @$scope.isAllTableSelected = true
            for _table in @tableList when not _table.selected and not _table.configured
                @$scope.isAllTableSelected = false
            @updateSelectionCounter()

        updateSelectionCounter: () =>
            @$scope.selectionCounter = 0
            for _table in @tableList when _table.selected and not _table.configured
                @$scope.selectionCounter++