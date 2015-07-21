app = require './virtdb-app.js'
ServerConnector = require './server-connector.js'

module.exports = app.factory 'CurrentUser', ['ServerConnector', (ServerConnector) ->
    new class CurrentUser

        user: null

        constructor: () ->

        get: (cb) =>
            if @user?
                cb @user
                return
            ServerConnector.getCurrentUser (user) =>
                if user? and user isnt ""
                    @user = user
                    cb user
                else
                    cb null

        logout: =>
            @user = null
]