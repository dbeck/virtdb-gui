app = angular.module 'virtdb'
app.controller 'DBConfigController', ['$scope', '$http', ($scope, $http) ->

    @selectedTables = []
    @requests = new Requests('')


    @addTable = (table) =>
        # @selectedTables.push(table)
        data =
            "table": table
            "schema": "data"
            "provider": "sap_data_provider"

        $http.post(@requests.dbConfig(), data).success (data) =>
             console.log data
        return

    return
]
