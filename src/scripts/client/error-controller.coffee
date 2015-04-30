app = require './virtdb-app.js'

module.exports = app.controller 'ErrorController',
        class ErrorController

            errorList: null

            constructor: ($timeout, $scope, ErrorService) ->
                @$timeout = $timeout
                @$scope = $scope
                @ErrorService = ErrorService
                # @ErrorService.addErrorListener(@onError)
                @errorList = []

            onError: (error) =>
                @errorList.push error

            removeError: (error) =>
                index = @errorList.indexOf(error)
                if index > -1
                    @errorList.splice(index,1)
