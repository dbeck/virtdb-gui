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
            @tableData = {}
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
            return

        onProviderChange: () =>
            @tableList = []
            @currentTablePosition = 0
            @$rootScope.currentProvider = @currentProvider
            @requests.setDataProvider @currentProvider
            if @currentProvider
                @getTableList()

        getTableList: () =>
            @$http.get(@requests.metaDataTableNames(@currentTablePosition, @currentTablePosition + @tableCount)).success (data) =>
                if data.length is 0
                    @isMoreTable = false
                    return

                @isMoreTable = data.length is @tableCount
                @tableList = data
            return

        getMetaData: () =>
            @$http.get(@requests.metaDataTable @currentTable).success (data) =>
                @tableMetaData = data
                @$scope.currentMeta = data
                @getData()
            return

        getData: () =>
            @tableData = {}
            @$http.get(@requests.dataTable @currentTable, @limit).success (data) =>
                @tableData = data
            return

        selectTable: (table) =>
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
            if @currentSearchPattern.length > 1
                @$http.get(@requests.metaDataTableNamesSearch(@currentSearchPattern)).success (data) =>
                    @tableList = data
            else
                @getTableList()
