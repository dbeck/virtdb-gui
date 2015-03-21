app = angular.module 'virtdb'
app.controller 'UserController',
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
