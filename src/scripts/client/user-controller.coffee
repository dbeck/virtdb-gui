app = require './virtdb-app.js'
ServerConnector = require './server-connector.js'

userController = app.controller 'UserController',
    class UserController
        constructor: ($scope, ServerConnector, $rootScope) ->
            @$scope = $scope
            @$rootScope = $rootScope
            @ServerConnector = ServerConnector
            @name = ""
            @isAdmin = false

            @$scope.userName = "Guest"
            @$scope.isAdmin = false
            @$scope.userList = []
            @$scope.editAction = "Create"

#            @$rootScope.$on "$routeChangeSuccess", (event, current, previous) =>
#                console.log event
#                console.log current
#                console.log previous
#                if current?.$$route?.originalPath is "/users"
#                    @getUserList()

            @ServerConnector.getCurrentUser (user) =>
                if user? and user isnt ""
                    @name = user.name
                    @isAdmin = user.isAdmin
                    @$scope.userName = @name
                    @$scope.isAdmin = @isAdmin

        getUserList: () =>
            @ServerConnector.getUserList (users) =>
                @$scope.userList = users

        sendUser: () =>
            data = {}
            if @$scope.editUserName is ""
                console.error "User name is have to be filled"
                return
            if @$scope.editUserPass is "" and @newUser
                console.error "Password is have to be filled when creating new user"
                return

            data["name"] = @$scope.editUserName
            data["isAdmin"] = @$scope.editUserIsAdmin
            if @$scope.editUserPass isnt ""
                data["password"] = @$scope.editUserPass

            finishAction = () =>
                @getUserList()
            if @newUser
                @ServerConnector.createUser data, finishAction
            else
                @ServerConnector.updateUser data, finishAction

        deleteUser: (id) =>
            @ServerConnector.deleteUser @$scope.userList[id].Name, () =>
                @getUserList()

        updateUser: (id) =>
            @$scope.editUserName = @$scope.userList[id].Name
            @$scope.editUserPass = ""
            @$scope.editUserIsAdmin = @$scope.userList[id].IsAdmin
            @newUser = false
            @$scope.editAction = "Update"

        createUser: =>
            @$scope.editUserName = ""
            @$scope.editUserPass = ""
            @$scope.editUserIsAdmin = false
            @newUser = true
            @$scope.editAction = "Create"

module.exports = userController
