app = require './virtdb-app.js'
ServerConnector = require './server-connector.js'
CurrentUser = require './current-user'
Validator = require './validator'

userController = app.controller 'UserController',
    class UserController
        constructor: ($scope, ServerConnector, $rootScope, CurrentUser, Validator) ->
            @Validator = Validator
            @$scope = $scope
            @$rootScope = $rootScope
            @ServerConnector = ServerConnector
            @name = ""
            @isAdmin = false

            @$scope.userName = ""
            @$scope.isAdmin = false
            @$scope.userList = []

            CurrentUser.get  (user) =>
                if user? and user isnt ""
                    @name = user.name
                    @isAdmin = user.isAdmin
                    @$scope.userName = @name
                    @$scope.isAdmin = @isAdmin

            if $rootScope.Features?.Security
                @getUserList()

        getUserList: () =>
            @ServerConnector.getUserList (users) =>
                @$scope.userList = users
            @ServerConnector.getDBUsers (dbUsers) =>
                @$scope.DBUserList = dbUsers

        createUser: () =>
            nameErr = @Validator.validateName @$scope.editUserName
            if nameErr?
                @$scope.error = nameErr.message
                return
            passErr = @Validator.validatePassword @$scope.editUserPass1, @$scope.editUserPass2
            if passErr?
                @$scope.error = passErr.message
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

#        addDBUser: (username) =>
#            @ServerConnector.addDBUser username, () =>
#                @getUserList()

        changeAdminStatus: (id) =>
            data =
                name: @$scope.userList[id].Name
                isAdmin: @$scope.userList[id].IsAdmin
            @ServerConnector.updateUser data, () =>
                @getUserList()

        login: =>
            @ServerConnector.login @$scope.username, @$scope.password, ->
                window.location = '/'

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
            @$rootScope.editUser = @$scope.userList[id]

module.exports = userController
