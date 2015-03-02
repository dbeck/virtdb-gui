app = angular.module 'virtdb'
app.controller 'DataProviderController',
    class DataProviderController

        @TABLE_LIST_DISPLAY_COUNT = 50
        @DATA_LIMIT = 20
        TABLE_LIST = "tablelist"
        DATA = "data"
        META_DATA = "metadata"

        constructor: ($rootScope, $scope, $http, $timeout, ServerConnector) ->
            @$rootScope = $rootScope
            @$scope = $scope
            @$http = $http
            @$timeout = $timeout
            @ServerConnector = ServerConnector
            @providers = []
            @$rootScope.provider = null
            @requestIds = {}

            @tableListEndTimerPromise = null

            @tableMetaData = null
            @tableList = null
            @isAllTableSelected = false

            @transposed = false
            @tableListPosition = 0
            @isMoreTable = true

            @tablesToFilter = []
            @isLoading = false
            @isLoadingTable = false

            @getDataProviders()

        getDataProviders: () =>
            @ServerConnector.getDataProviders(
                (data) =>
                    @providers = data
                    @providers.sort()
                    @selectProvider(@providers[0])
            )
            return

        selectProvider: (provider) =>
            if provider is @$rootScope.provider
                return
            @$rootScope.provider = provider
            angular.element("#searchInput").focus()
            @resetProviderLevelView()
            @requestTableList()

        resetTableLevelView: () =>
            @tableData = null
            @$scope.dataHeader = []
            @$scope.dataRows = []
            @$scope.meta = null
            @$scope.fieldDescription = null
            @$scope.field = null
            @$scope.metaData = null

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

        requestTableList: () =>
            requestData =
                tables: @tablesToFilter
                search: @$scope.search
                provider: @$rootScope.provider
                from: @tableListPosition + 1
                to: @tableListPosition + DataProviderController.TABLE_LIST_DISPLAY_COUNT

            @stopPreviousRequest @TABLE_LIST
            @requestIds[@TABLE_LIST] = @ServerConnector.getTableList(requestData, @onTableList)
            @isLoading = true
            return

        onTableList: (data) =>
            if not data?
                return
            @isLoading = false

            delete @requestIds[@TABLE_LIST]
            @tableList = []
            if @tableListEndTimerPromise?
                @$timeout.cancel(@tableListEndTimerPromise)
                @tableListEndTimerPromise = null

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
            @tableListEndTimerPromise = @$timeout(() =>
                @requestConfiguredTables()
            , 500)
            return

        requestMetaData: () =>
            @isLoadingTable = true
            requestData =
                provider: @$rootScope.provider
                table: @$scope.table

            @stopPreviousRequest @META_DATA
            @requestIds[@META_DATA] = @ServerConnector.getMetaData(requestData, @onMetaData)
            return

        onMetaData: (data) =>
            delete @requestIds[@META_DATA]
            @tableMetaData = data
            @$scope.meta = data
            if data?.Fields?.length > 0
                @$scope.dataHeader = data.Fields.map( (item) -> item.Name )
            else
                @$scope.dataHeader = []
            @requestData()

        requestData: () =>
            requestData =
                provider: @$rootScope.provider
                table: @$scope.table
                count: DataProviderController.DATA_LIMIT

            @stopPreviousRequest @DATA
            @requestIds[@DATA] = @ServerConnector.getData(requestData, @onData)
            return

        onData: (data) =>
            @isLoadingTable = false
            delete @requestIds[@DATA]
            @$scope.dataRows = data

        selectTable: (table) =>
            @$scope.table = table
            @resetTableLevelView()
            @requestMetaData()
            return

        selectField: (field) =>
            @$scope.$apply () =>
                if @$scope.field == field
                    @$scope.field = null
                    @$scope.metaData = null
                else
                    @$scope.field = field
                    @$scope.metaData = (fieldMeta for fieldMeta in @tableMetaData.Fields when fieldMeta.Name is field)[0]
            return

        transposeData: () =>
            @transposed = !@transposed

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
                        @$timeout(@requestConfiguredTables, 2000)
            return

        requestConfiguredTables: () =>
            data = provider: @$scope.provider
            @ServerConnector.getDBConfig(data, @onConfiguredTables)
            return

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
            @tableListPosition = 0
            @requestTableList()

        checkTableFilter: () =>
            @tablesToFilter = []
            for item in @$scope.tableListFilter.split("\n") when item.length > 0
                @tablesToFilter.push item

        changeSelection: (table) =>
            @$scope.$apply () =>
                table.selected = not table.selected
                @updateSelectionCounter()

        selectAllTableChanged: () =>
            for table in @tableList when not table.configured
                table.selected = @isAllTableSelected
            @updateSelectionCounter()

        tableSelectionChanged: () =>
            @isAllTableSelected = true
            for _table in @tableList when not _table.selected and not _table.configured
                @isAllTableSelected = false
            @updateSelectionCounter()

        updateSelectionCounter: () =>
            @$scope.selectionCounter = 0
            for _table in @tableList when _table.selected and not _table.configured
                @$scope.selectionCounter++

        stopPreviousRequest: (type) =>
            if @requestIds[type]?
                @ServerConnector.cancelRequest @requestIds[type]
.directive 'virtdbTable', virtdbTableDirective
.directive 'tableList', tableListDirective 
