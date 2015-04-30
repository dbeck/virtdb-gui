app = require './virtdb-app.js'

virtdbTableDirective = require './virtdb-table.js'

dataProviderController = app.controller 'DataProviderController',
    class DataProviderController

        @DATA_LIMIT = 20
        DATA = "data"
        META_DATA = "metadata"

        constructor: ($scope, ServerConnector) ->
            @$scope = $scope
            @ServerConnector = ServerConnector
            @requestIds = {}
            @$scope.selectedProvider = null
            @$scope.$watch 'selectedProvider', (newValue, oldValue) =>
                angular.element("#searchInput").focus()
                @resetTableLevelView()
                @$scope.$broadcast "selectedProviderChanged", newValue

            @$scope.$on 'tableSelected', (event, table) =>
                @$scope.table = table
                @resetTableLevelView()
                @requestMetaData()

            @tableMetaData = null
            @tableList = null
            @isAllTableSelected = false

            @transposed = false
            @isMoreTable = true

            @isLoading = false
            @isLoadingTable = false

        resetTableLevelView: () =>
            @tableData = null
            @$scope.dataHeader = []
            @$scope.dataRows = []
            @$scope.meta = null
            @$scope.fieldDescription = null
            @$scope.field = null
            @$scope.metaData = null

        requestMetaData: () =>
            @isLoadingTable = true
            requestData =
                provider: @$scope.selectedProvider
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
                provider: @$scope.selectedProvider
                table: @$scope.table
                count: DataProviderController.DATA_LIMIT

            @stopPreviousRequest @DATA
            @requestIds[@DATA] = @ServerConnector.getData(requestData, @onData)
            return

        onData: (data) =>
            @isLoadingTable = false
            delete @requestIds[@DATA]
            @$scope.dataRows = data

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

        stopPreviousRequest: (type) =>
            if @requestIds[type]?
                @ServerConnector.cancelRequest @requestIds[type]

dataProviderController.directive 'virtdbTable', virtdbTableDirective

module.exports = dataProviderController
