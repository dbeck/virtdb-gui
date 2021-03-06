app = require './virtdb-app.js'
tableListDirective = require './tablelist.js'
CurrentUser = require './current-user'

ICON_HIDDEN = "transparent fa fa-check"
ICON_SPINNER = "fa fa-spin fa-spinner"
ICON_OK = "fa fa-check"
ICON_ERROR = "fa fa-times error"

hideIcon = (icon) ->
    setTimeout ->
        icon.className = ICON_HIDDEN
    , 1000

module.exports = app.controller 'TableListController',
    class TableListController
        @ITEMS_PER_PAGE = 50

        constructor: ($scope, $timeout, $rootScope, CurrentUser, ServerConnector) ->
            @$scope = $scope
            @$rootScope = $rootScope
            @$timeout = $timeout
            @ServerConnector = ServerConnector
            @$scope.tableListCount = 0
            @tablesToFilter = []
            @tableListPosition = 0
            @$scope.$on "selectedProviderChanged", @providerChanged
            @tableListEndTimerPromise = null
            @CurrentUser = CurrentUser

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
            @$scope.materializedCounter = 0
            configuredTableHash = {}
            materializedTableHash = {}
            for table in configuredTableList
                configuredTableHash[table.name] = true
                materializedTableHash[table.name] = table.materialized
            for _table in @tableList
                isConfigured = configuredTableHash[_table.name]?
                isMaterialized = materializedTableHash[_table.name]? and materializedTableHash[_table.name]
                if isConfigured
                    @$scope.configuredCounter += 1
                if isMaterialized
                    @$scope.materializedCounter += 1
                _table.configured = isConfigured
                _table.selected = isConfigured
                _table.outdated = isConfigured
                _table.materialized = isMaterialized

        changeDbConfigStatus: (table) =>
            icon = document.getElementById("tableIcon#{table.name}")
            icon.className = ICON_SPINNER
            data =
                table: table.name
                provider: @$scope.selectedProvider
            if table.configured
                @ServerConnector.deleteDBConfig data, =>
                    icon.className = ICON_OK
                    @requestConfiguredTables()
                    hideIcon icon
                , =>
                    console.log "Error with dbConfig request"
                    icon.className = ICON_ERROR
                    hideIcon icon
            else
                @ServerConnector.sendDBConfig data, =>
                    icon.className = ICON_OK
                    @requestConfiguredTables()
                    hideIcon icon
                , =>
                    console.log "Error with dbConfig request"
                    icon.className = ICON_ERROR
                    hideIcon icon

        changeMaterializeStatus: (table) =>
            icon = document.getElementById("tableIcon#{table.name}")
            icon.className = ICON_SPINNER
            data =
                table: table.name
                provider: @$scope.selectedProvider
            if table.materialized
                @ServerConnector.deleteMaterialization data, =>
                    icon.className = ICON_OK
                    @requestConfiguredTables()
                    hideIcon icon
                , =>
                    console.log "Error with dbConfig materialization request"
                    icon.className = ICON_ERROR
                    hideIcon icon
            else
                @ServerConnector.addMaterialization data, =>
                    icon.className = ICON_OK
                    @requestConfiguredTables()
                    if @$rootScope.Features.MaterializationSqlCommand
                        @CurrentUser.get (user) =>
                            @$rootScope.matViewPath = "#{user.name}_#{@$scope.selectedProvider}_#{table.name}"
                        $('#refreshMatViewCommand').modal("show")
                    hideIcon icon
                , =>
                    console.log "Error with dbConfig materialization request"
                    icon.className = ICON_ERROR
                    hideIcon icon

        filterTableList: () =>
            @$scope.search = ""
            @tableListPosition = 0
            @requestTableList @$scope.selectedProvider
.directive 'tableList', tableListDirective
