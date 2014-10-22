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

        requestId: null

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

            @requestId = {}

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
            @resetProviderLevelView()
            @$rootScope.currentProvider = @currentProvider
            @requests.setDataProvider @currentProvider
            if @currentProvider
                @getTableList()

        resetTableLevelView: () =>
            @tableData = {}
            @$scope.currentMeta = {}
            @$scope.fieldDescription = {}
            @currentField = ""

        resetProviderLevelView: () =>
            @resetTableLevelView()
            @currentTable = ""
            @tableList = []
            @currentTablePosition = 0
            @currentSearchPattern = ""
            @$scope.tableNamesFrom = 0
            @$scope.tableNamesTo = 0
            @$scope.tableNamesCount = 0

        getTableList: () =>
            @tableList = []
            @requestId["tableList"] = @generateRequestId()
            @$http.get(@requests.metaDataTableNames(@currentSearchPattern, @currentTablePosition + 1, @currentTablePosition + @tableCount, @requestId["tableList"])).success (response) =>
                if response.id isnt @requestId["tableList"]
                    console.log "Table list response outdated."
                    return
                data = response.data
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
            @requestId["metaData"] = @generateRequestId()
            @$http.get(@requests.metaDataTable @currentTable, @requestId["metaData"]).success (response) =>
                if response.id isnt @requestId["metaData"]
                    console.log "Meta data response outdated."
                    return
                data = response.data
                @tableMetaData = data
                @$scope.currentMeta = data
                @getData()
            return

        getData: () =>
            @requestId["data"] = @generateRequestId()
            @tableData = null
            @$http.get(@requests.dataTable @currentTable, @limit, @requestId["data"]).success (response) =>
                if response.id isnt @requestId["data"]
                    console.log "Data response outdated."
                    return
                data = response.data
                @tableData = data
            return

        selectTable: (table) =>
            @resetTableLevelView()
            @currentTable = table
            @getMetaData()
            return

        selectField: (field) =>
            @currentField = field
            @$scope.currentMeta = fieldMeta for fieldMeta in @tableMetaData.Fields when fieldMeta.Name is field
            @$scope.fieldDescription = @$scope.currentMeta.Desc
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

        generateRequestId: () =>
            id = Math.floor(Math.random() * 1000000) + 1
            return id
