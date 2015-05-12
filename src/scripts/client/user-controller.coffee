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
            @$scope.userName = "Guest"
            @ServerConnector.getCurrentUser (user) =>
                if user? and user isnt ""
                    @name = user.displayName or user.username
                    @$scope.userName = @name

            @ServerConnector.getAuthenticationMethods (methods) =>
                @methods = methods
                console.log "Setting @methods:", @methods

module.exports = userController
