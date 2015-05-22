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

            @$scope.userName = "Config"
            @$scope.isAdmin = false
            @$scope.userList = []

            @ServerConnector.getCurrentUser (user) =>
                if user? and user isnt ""
                    @name = user.name
                    @isAdmin = user.isAdmin
                    @$scope.userName = @name
                    @$scope.isAdmin = @isAdmin

            @ServerConnector.getUserList (users) =>
                @$scope.userList = users

        getUserList: () =>
            @ServerConnector.getUserList (users) =>
                @$scope.userList = users

        validateUsername: () =>
            if @$scope.editUserName?.length is 0
                @$scope.error =
                    message: "Username is empty"
                return false
            return true

        validatePassword: () =>
            if @$scope.editUserPass1 isnt @$scope.editUserPass2
                @$scope.error =
                    message: "Password is not matching with its confirmation"
                return false
            if @$scope.editUserPass1?.length is 0
                @$scope.error =
                    message: "Password is empty"
                return false
            return true

        createUser: () =>
            if not @validateUsername() or not @validatePassword()
                return
            data =
                name: @$scope.editUserName
                isAdmin: @$scope.editUserIsAdmin
                password: @$scope.editUserPass1
            @ServerConnector.createUser data, () =>
                $('#create-user-modal').modal("hide")
                @getUserList()

        deleteUser: () =>
            @ServerConnector.deleteUser @$scope.editUserName, () =>
                @getUserList()

        changePassword: () =>
            if not @validatePassword()
                return
            data =
                name: @$scope.editUserName
                isAdmin: @$scope.editUserIsAdmin
                password: @$scope.editUserPass1
            @ServerConnector.updateUser data, () =>
                $('#change-password-modal').modal("hide")
                @getUserList()

        changeAdminStatus: (id) =>
            data =
                name: @$scope.userList[id].Name
                isAdmin: @$scope.userList[id].IsAdmin
            @ServerConnector.updateUser data, () =>
                @getUserList()

        initCreateUser: () =>
            @$scope.error = null
            @$scope.editUserName = ""
            @$scope.editUserPass1 = ""
            @$scope.editUserPass2 = ""
            @$scope.editUserIsAdmin = false

        initDeleteUser: (id) =>
            @$scope.error = null
            @$scope.editUserName = @$scope.userList[id].Name
            @$scope.editUserPass1 = ""
            @$scope.editUserPass2 = ""
            @$scope.editUserIsAdmin = false

        initChangePassword: (id) =>
            @$scope.error = null
            @$scope.editUserPass1 = ""
            @$scope.editUserPass2 = ""
            @$scope.editUserName = @$scope.userList[id].Name
            @$scope.editUserIsAdmin = @$scope.userList[id].IsAdmin

module.exports = userController
