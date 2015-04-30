app = require './virtdb-app.js'

ServerConnector = require './server-connector.js'

userController = app.controller 'UserController',
    class UserController
        constructor: ($scope, ServerConnector) ->
            @methods =
                local: false
                github: false
                facebook: false
            @$scope = $scope
            @ServerConnector = ServerConnector
            @name = ""
            @ServerConnector.getCurrentUser (user) =>
                @name = user.displayName or user.username

            @ServerConnector.getAuthenticationMethods (methods) =>
                @methods = methods
                console.log "Setting @methods:", @methods

module.exports = userController
