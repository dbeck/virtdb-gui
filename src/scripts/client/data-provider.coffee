VIRTDB = React.createClass(
    displayName: 'VIRTDB'
    render: ->
        clickHandler = (fieldName) =>
            return (ev) =>
                @props.callback fieldName

        style = (field) =>
            if @props.selectedField == field
                "info"
            else
                ""

        rows = []
        if @props.data?
            transposedData = []
            for row in @props.data
                children = []
                for field, index in row
                    item = React.DOM.td { onClick: clickHandler(@props.header[index]), className: style(@props.header[index])}, field
                    if @props.transposed
                        transposedData[index] ?= [ React.DOM.th {onClick: clickHandler(@props.header[index]), className: style(@props.header[index])}, @props.header[index] ]
                        transposedData[index].push item
                    else
                        children.push item
                if not @props.transposed
                    rows.push React.DOM.tr(null, children)
            if @props.transposed
                for row in transposedData
                    rows.push React.DOM.tr(null, row)

        headItems = []
        if @props.header?
            for field in @props.header
                headItems.push React.DOM.th { onClick: clickHandler(field), className: style(field)}, field
        tableParts = []
        if not @props.transposed
            headerRow = React.DOM.tr null, headItems
            tableParts.push React.DOM.thead null, headerRow
        tableParts.push React.DOM.tbody null, rows
        return React.DOM.table {className: "table table-bordered"}, tableParts
)

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

            @transposed = false
            @tableListPosition = 0
            @isMoreTable = true

            @tablesToFilter = []

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
            requestData =
                tables: @tablesToFilter
                search: @$scope.search
                provider: @$rootScope.provider
                from: @tableListPosition + 1
                to: @tableListPosition + DataProviderController.TABLE_LIST_DISPLAY_COUNT

            @stopPreviousRequest @TABLE_LIST
            @requestIds[@TABLE_LIST] = @ServerConnector.getTableList(requestData, @onTableList)
            return

        onTableList: (data) =>
            delete @requestIds[@TABLE_LIST]
            @tableList = []
            if not data?
                return

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
            delete @requestIds[@DATA]
            @$scope.dataRows = data

        selectTable: (table) =>
            @$scope.table = table
            @resetTableLevelView()
            @requestMetaData()
            return

        selectField: (field) =>
            @$scope.$apply () =>
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
                        @$timeout(@requestConfiguredTables, 1000)
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

        stopPreviousRequest: (type) =>
            if @requestIds[type]?
                @ServerConnector.cancelRequest @requestIds[type]
.directive 'virtdbTable', ->
    {
        restrict: 'E'
        scope:
            data: '='
            header: '='
            callback: '='
            selectedField: '='
            transposed: '='
        link: (scope, el, attrs) ->
            display = (data, header, callback, selectedField, transposed) =>
                React.render VIRTDB(data: data, header: header, callback: callback, selectedField: selectedField, transposed: transposed), el[0]
            scope.$watch 'data', (newValue, oldValue) ->
                display newValue, scope.header, scope.callback, scope.selectedField, scope.transposed
            scope.$watch 'selectedField', (newValue, oldValue) ->
                display scope.data, scope.header, scope.callback, newValue, scope.transposed
            scope.$watch 'transposed', (newValue, oldValue) ->
                display scope.data, scope.header, scope.callback, scope.selectedField, newValue
            return

    }
