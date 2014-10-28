app = angular.module 'virtdb'
app.controller 'ErrorController',
        class ErrorController
            constructor: (@$timeout, @$scope, @ErrorService) ->
                @ErrorService.addErrorListener(@onError)
                @errorList = []
                @$scope.currentError = null

            onError: (error) =>
                @errorList.push error
                if not @$scope.currentError?
                    @processErrors()

            processErrors: () =>
                if @errorList.length > 0
                    @$scope.currentError = @errorList[0]
                    @errorList.splice(0,1);
                    @$timeout(@processErrors, 3000)
                else
                    @$scope.currentError = null

            showError: () =>
                return @$scope.currentError isnt null


