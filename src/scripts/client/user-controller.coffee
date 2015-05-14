app = require './virtdb-app.js'

ServerConnector = require './server-connector.js'

userController = app.controller 'UserController',
    class UserController
        constructor: ($scope, ServerConnector) ->
            @$scope = $scope
            @ServerConnector = ServerConnector
            @name = ""
            @$scope.userName = "Guest"
            @ServerConnector.getCurrentUser (user) =>
                if user? and user isnt ""
                    @name = user.displayName or user.name
                    @$scope.userName = @name


module.exports = userController
