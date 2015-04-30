app = require './virtdb-app.js'
module.exports = app.factory 'ErrorService', [ ->
    new class ErrorService

        constructor: () ->
            @errorListeners = []

        addErrorListener: (callback) =>
            @errorListeners.push callback
            return

        errorHappened: (status, error) =>
            if status == 401
                window.location = '/'
                return
            console.error error
            for callback in @errorListeners
                callback error
            return
]
