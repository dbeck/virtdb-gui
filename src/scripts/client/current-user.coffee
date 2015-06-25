app = require './virtdb-app.js'
ServerConnector = require './server-connector.js'

module.exports = app.factory 'CurrentUser', ['ServerConnector', (ServerConnector) ->
    new class CurrentUser
        constructor: () ->

        get: (cb) =>
            ServerConnector.getCurrentUser (user) =>
                if user? and user isnt ""
                    cb user
                else
                    cb null
]