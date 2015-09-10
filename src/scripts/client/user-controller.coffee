app = require './virtdb-app.js'
ServerConnector = require './server-connector.js'
CurrentUser = require './current-user'
Validator = require './validator'

CHAR_C = 99
ENTER = 13

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
            @$scope.loginError = null

            $('#user-to-db-modal').on 'shown.bs.modal', ->
                $('[autofocus]', this).focus()

            $('#createUserModal').off()
            $('#createUserModal').on 'hidden.bs.modal', ->
                initCreateUser $scope

            $('#createUserModal').on 'shown.bs.modal', ->
                initCreateUser $scope
                $('[autofocus]', this).focus()

            $('#deleteConfirmModal').on 'keypress', (e) ->
                if e.which is ENTER
                    $('#deleteConfirmModal form').submit()

            $(document).on 'keypress', (e) ->
                if e.which is CHAR_C
                    $('#createUserModal').modal('show')

            $scope.anyoneElse = (users) ->
                return Object.keys(users).length > 1

            $scope.changeAdminStatus = (id) ->
                data =
                    name: $scope.userList[id].Name
                    isAdmin: $scope.userList[id].IsAdmin
                ServerConnector.updateUser data, =>
                    getUserList ServerConnector, $scope

            $scope.createUser = (editUserName, editUserPass1, editUserPass2, editUserIsAdmin) ->
                nameErr = Validator.validateName editUserName
                if nameErr?
                    $scope.error = nameErr.message
                    return
                passErr = Validator.validatePassword editUserPass1, editUserPass2
                if passErr?
                    $scope.error = passErr.message
                    return
                data =
                    name: editUserName
                    isAdmin: editUserIsAdmin
                    password: editUserPass1
                ServerConnector.createUser data, (err) =>
                    $('#createUserModal').modal('hide')
                    getUserList ServerConnector, $scope

            $scope.deleteUser = (editUserName) ->
                ServerConnector.deleteUser editUserName, () ->
                    $('#deleteConfirmModal').modal('hide')
                    getUserList(ServerConnector, $scope)

            $scope.initDeleteUser = (id) ->
                $scope.error = null
                $scope.editUserName = $scope.userList[id].Name
                $scope.editUserPass1 = ""
                $scope.editUserPass2 = ""
                $scope.editUserIsAdmin = false

            $scope.initUserToDB = (id) ->
                $scope.editUserName = $scope.userList[id].Name
                $scope.editUserIsAdmin = $scope.userList[id].IsAdmin
                $scope.editUserPass1 = ""
                $scope.editUserPass2 = ""
                $scope.error = ""

            $scope.addUserToDB = () ->
                $scope.error = ""
                err = Validator.validatePassword $scope.editUserPass1, $scope.editUserPass2
                if err?
                    $scope.error = err.message
                    return
                $scope.error = null
                data =
                    name: $scope.editUserName
                    password: $scope.editUserPass1
                    isAdmin: $scope.editUserIsAdmin
                ServerConnector.addUserToDB data,
                    () ->
                        $('#user-to-db-modal').modal("hide")
                        getUserList ServerConnector, $scope
                    ,
                    () ->
                        $scope.error = "Something went wrong during addig user to db."


            $scope.initChangePassword = (id) ->
                $rootScope.editUser = $scope.userList[id]

            CurrentUser.get  (user) =>
                if user? and user isnt ""
                    @name = user.name
                    @isAdmin = user.isAdmin
                    @$scope.userName = @name
                    @$scope.isAdmin = @isAdmin

            if $rootScope.Features?.Security
                getUserList ServerConnector, $scope

        getUserList = (ServerConnector, scope) ->
            ServerConnector.getUserList (users) =>
                scope.userList = users
            ServerConnector.getDBUsers (dbUsers) =>
                scope.DBUserList = dbUsers

        login: =>
            @$scope.loginError = null
            @ServerConnector.login @$scope.username, @$scope.password,
                () =>
                    window.location = '/'
                ,() =>
                    @$scope.loginError = "Invalid username or password!"

        initCreateUser = (scope) ->
            scope.$apply ->
                scope.error = null
                scope.editUserName = ""
                scope.editUserPass1 = ""
                scope.editUserPass2 = ""
                scope.editUserIsAdmin = false

module.exports = userController
