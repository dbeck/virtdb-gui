app = require './virtdb-app.js'
ServerConnector = require './server-connector.js'

module.exports = app.factory 'CurrentUser', ['ServerConnector', (ServerConnector) ->
    new class CurrentUser
        constructor: () ->

        get: (cb) =>
            if @user
                cb @user
            else
                ServerConnector.getCurrentUser (user) =>
                    if user? and user isnt ""
                        @user = user
                        cb @user
                    else
                        cb null
            return
]