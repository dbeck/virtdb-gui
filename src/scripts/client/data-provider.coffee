app = angular.module 'virtdb'
app.controller 'DataProviderController',
    class DataProviderController


        requests: null
        currentProvider: null
        providers: null

        tableMetaData: null
        tableData: null
        tableList: null
        fieldList: null
        currentTable: null
        currentField: null
        limit: null
        rowIndexes: null
        isHeaderColumn: null

        currentTablePosition: null
        isMoreTable: null
        tableCount: null
        currentSearchPattern: null

        constructor: (@$rootScope, @$scope, @$http) ->
            @requests = new Requests("")
            @currentProvider = ''
            @providers = []

            @tableMetaData = {}
            @tableData = null
            @tableList = []
            @fieldList = []
            @currentTable = ''
            @currentField = ''
            @limit = 10
            @rowIndexes = [0..@limit-1]
            @isHeaderColumn = false
            @currentTablePosition = 0
            @isMoreTable = true
            @tableCount = 10
            @currentSearchPattern = ""
            @$rootScope.currentProvider = ""
            @getDataProviders()
            return

        getDataProviders: () =>
            @$http.get(@requests.endpoints()).success (data) =>
                services = {}
                for endpoint in data
                    services[endpoint.Name] ?= []
                    services[endpoint.Name].push(endpoint.SvcType)
                for endpointName, serviceTypes of services
                    if "META_DATA" in serviceTypes and "QUERY" in serviceTypes and "COLUMN" in serviceTypes
                        @providers.push endpointName
                @selectProvider(@providers[0])
            return

        selectProvider: (provider) =>
            if provider is @currentProvider
                return
            @currentProvider = provider
            @resetView()
            @$rootScope.currentProvider = @currentProvider
            @requests.setDataProvider @currentProvider
            if @currentProvider
                @getTableList()

        resetView: () =>
            @tableList = []
            @tableData = {}
            @$scope.currentMeta = {}
            @currentTablePosition = 0
            @currentSearchPattern = ""
            @$scope.tableNamesFrom = 0
            @$scope.tableNamesTo = 0
            @$scope.tableNamesCount = 0

        getTableList: () =>
            @tableList = []
            @$http.get(@requests.metaDataTableNames(@currentSearchPattern, @currentTablePosition + 1, @currentTablePosition + @tableCount)).success (data) =>
                @$scope.tableNamesCount = data.count
                if data.count > 0
                    @$scope.tableNamesFrom = data.from + 1
                    @$scope.tableNamesTo = data.to + 1
                else
                    @$scope.tableNamesFrom = data.from
                    @$scope.tableNamesTo = data.to

                if data.results.length is 0
                    @isMoreTable = false
                    return

                @isMoreTable = data.results.length is @tableCount
                @tableList = data.results
            return

        getMetaData: () =>
            @$http.get(@requests.metaDataTable @currentTable).success (data) =>
                @tableMetaData = data
                @$scope.currentMeta = data
                @getData()
            return

        getData: () =>
            @tableData = null
            @$http.get(@requests.dataTable @currentTable, @limit).success (data) =>
                @tableData = data
            return

        selectTable: (table) =>
            @tableData = null
            @currentTable = table
            @getMetaData()
            return

        selectField: (field) =>
            @currentField = field
            @$scope.currentMeta = fieldMeta for fieldMeta in @tableMetaData.Fields when fieldMeta.Name is field
            return

        transposeData: () =>
            @isHeaderColumn = !@isHeaderColumn

        getNextTables: () =>
            if @isMoreTable
                @currentTablePosition = @currentTablePosition + @tableCount
                @getTableList()

        getPreviousTables: () =>
            if @currentTablePosition isnt 0
                @currentTablePosition = @currentTablePosition - @tableCount
                @getTableList()

        searchTableNames: () =>
            @currentTablePosition = 0
            @getTableList()
