app = angular.module 'virtdb'
app.controller 'ErrorController',
        class ErrorController
            constructor: (@$timeout, @$scope, @ErrorService) ->
                @ErrorService.addErrorListener(@onError)
                @errorList = []

            onError: (error) =>
                @errorList.push error

            removeError: (error) =>
                index = @errorList.indexOf(error)
                if index > -1
                    @errorList.splice(index,1)
