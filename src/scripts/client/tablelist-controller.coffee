app = require './virtdb-app.js'
tableListDirective = require './tablelist.js'

module.exports = app.controller 'TableListController',
    class TableListController
        @ITEMS_PER_PAGE = 50

        constructor: ($scope, $timeout, ServerConnector) ->
            @$scope = $scope
            @$timeout = $timeout
            @ServerConnector = ServerConnector
            @$scope.tableListCount = 0
            @tablesToFilter = []
            @tableListPosition = 0
            @$scope.$on "selectedProviderChanged", @providerChanged
            @tableListEndTimerPromise = null

        providerChanged: (event, provider) =>
            @resetProviderLevelView()
            if provider?
                @requestTableList provider

        resetProviderLevelView: () =>
            @tableList = []
            @tableListPosition = 0
            @$scope.table = null
            @$scope.search = ""
            @$scope.tableListFrom = 0
            @$scope.tableListTo = 0
            @$scope.configuredCounter = 0
            @$scope.tableListCount = null
            @tablesToFilter = []
            @$scope.tableListFilter = ""

        refresh: (provider) =>
            @$scope.refreshing = true
            resetButton = =>
                @$scope.refreshing = false
                @$scope.$broadcast "selectedProviderChanged", provider

            @ServerConnector.refreshTableList provider, resetButton, resetButton

        requestTableList: (provider) =>
            requestData =
                tables: @tablesToFilter
                search: @$scope.search
                provider: provider
                from: @tableListPosition + 1
                to: @tableListPosition + TableListController.ITEMS_PER_PAGE

            @ServerConnector.cancelRequest @previousRequest
            @previousRequest = @ServerConnector.getTableList requestData, @onTableList, @finishedLoading
            @isLoading = true
            return

        onTableList: (data) =>
            if not data?
                return
            @finishedLoading()

            @$scope.tableListCount = data.count
            @$scope.tableListFrom = data.from
            @$scope.tableListTo = data.to
            @$scope.configuredCounter = 0
            @isAllTableSelected = false
            @fillTableList data
            @scheduleDBConfigQuery 500

        finishedLoading: (response, status) =>
            @isLoading = false
            if status isnt 0
                @previousRequest = null
                @cancelDBConfigLoad()

        cancelDBConfigLoad: =>
            if @tableListEndTimerPromise?
                @$timeout.cancel @tableListEndTimerPromise
                @tableListEndTimerPromise = null

        fillTableList: (data) =>
            @tableList = []
            for tableName in data.results
                @tableList.push
                    name: tableName
                    selected: false
                    configured: false
                    outdated: false

        scheduleDBConfigQuery: (delay) =>
            @tableListEndTimerPromise = @$timeout () =>
                @requestConfiguredTables()
            , delay

        getNextTables: () =>
            newPosition = @tableListPosition + TableListController.ITEMS_PER_PAGE
            if newPosition < @$scope.tableListCount
                @tableListPosition = newPosition
                @requestTableList @$scope.selectedProvider

        getPreviousTables: () =>
            if @tableListPosition isnt 0
                @tableListPosition = @tableListPosition - TableListController.ITEMS_PER_PAGE
                @requestTableList @$scope.selectedProvider

        selectTable: (table) =>
            @$scope.table = table.name
            @$scope.$emit "tableSelected", table.name

        searchTableNames: () =>
            @tableListPosition = 0
            @requestTableList @$scope.selectedProvider

        checkTableFilter: () =>
            @tablesToFilter = []
            for item in @$scope.tableListFilter.split("\n") when item.length > 0
                @tablesToFilter.push item

        tableSelectionChanged: (table) =>
            @isAllTableSelected = true
            for _table in @tableList when not _table.selected and not _table.configured
                @isAllTableSelected = false

        requestConfiguredTables: () =>
            data = provider: @$scope.selectedProvider
            @ServerConnector.getDBConfig(data, @onConfiguredTables)
            return

        onConfiguredTables: (configuredTableList) =>
            @$scope.configuredCounter = 0
            for _table in @tableList
                _table.configured = false
                _table.selected = false
                _table.outdated = false
                for table in configuredTableList
                    if table is _table.name
                        @$scope.configuredCounter += 1
                        _table.configured = true
                        _table.selected = true
                        _table.outdated = true

        changeStatus: (table) =>
            data =
                table: table.name
                provider: @$scope.selectedProvider
            if table.configured
                @ServerConnector.deleteDBConfig data, @requestConfiguredTables
            else
                @ServerConnector.sendDBConfig data, @requestConfiguredTables

        filterTableList: () =>
            @$scope.search = ""
            @tableListPosition = 0
            @requestTableList @$scope.selectedProvider
.directive 'tableList', tableListDirective
