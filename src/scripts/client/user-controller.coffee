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
                console.log "Init delete user: ", $scope.editUserName
                $scope.editUserPass1 = ""
                $scope.editUserPass2 = ""
                $scope.editUserIsAdmin = false

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

        addUserToDB: (id) =>
            err = @Validator.validatePassword @$scope.editUserPass1, @$scope.editUserPass2
            if err?
                @$scope.error = err.message
                return
            @$scope.error = null
            data =
                name: @$scope.editUserName
                password: @$scope.editUserPass1
                isAdmin: @$scope.editUserIsAdmin
            @ServerConnector.addUserToDB data, () =>
                $('#user-to-db-modal').modal("hide")
                @getUserList(@ServerConnector, @$scope)

        changeAdminStatus: (id) =>
            data =
                name: @$scope.userList[id].Name
                isAdmin: @$scope.userList[id].IsAdmin
            @ServerConnector.updateUser data, =>
                getUserList @ServerConnector, @$scope

        login: =>
            @ServerConnector.login @$scope.username, @$scope.password, ->
                window.location = '/'

        initCreateUser = (scope) ->
            scope.$apply ->
                scope.error = null
                scope.editUserName = ""
                scope.editUserPass1 = ""
                scope.editUserPass2 = ""
                scope.editUserIsAdmin = false

        initChangePassword: (id) =>
            @$rootScope.editUser = @$scope.userList[id]

        initUserToDB: (id) =>
            @$scope.editUserName = @$scope.userList[id].Name
            @$scope.editUserIsAdmin = @$scope.userList[id].IsAdmin
            @$scope.editUserPass1 = ""
            @$scope.editUserPass2 = ""

module.exports = userController
