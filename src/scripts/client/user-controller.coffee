app = require './virtdb-app.js'

ServerConnector = require './server-connector.js'

userController = app.controller 'UserController',
    class UserController
        constructor: ($scope, ServerConnector) ->
            @$scope = $scope
            @ServerConnector = ServerConnector
            @name = ""
            @ServerConnector.getCurrentUser (user) =>
                console.log user
                @name = user.displayName or user.name

module.exports = userController
