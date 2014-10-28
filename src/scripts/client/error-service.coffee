app = angular.module 'virtdb'
app.factory 'ErrorService', [ ->
    new class ErrorService

        constructor: () ->
            @errorListeners = []

        addErrorListener: (callback) =>
            @errorListeners.push callback
            return

        errorHappened: (error) =>
            console.error error
            for callback in @errorListeners
                callback error
            return
]