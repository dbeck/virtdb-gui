app = angular.module 'virtdb'
app.controller 'DBConfigController',
    class DBConfigController
        selectedTables: null
        requests: null
        currentProvider: null

        constructor: (@$rootScope, @$scope, @$http) ->
            @selectedTables = []
            @requests = new Requests('')
            @$rootScope.$watch "currentProvider", () =>
                @currentProvider = @$rootScope.currentProvider
            return

        selectTable: (table) =>
            if table not in @selectedTables
                @selectedTables.push table
            else
                @selectedTables.splice @selectedTables.indexOf table, 1


        addTables: () =>
            for table in @selectedTables
                data =
                    "table": table
                    "schema": "data"
                    "provider": @currentProvider

                @$http.post(@requests.dbConfig(), data).success (data) =>
                     console.log data
            return
