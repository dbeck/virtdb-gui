app = require './virtdb-app.js'
ServerConnector = require './server-connector'
CurrentUser = require './current-user'
Validator = require './validator'

ENTER = 13

module.exports = app.controller 'ChangeUserPassword',
    class ChangeUserPassword
        constructor: ($scope, ServerConnector, $rootScope, CurrentUser, Validator) ->
            $('#changePasswordModal').off()
            $('#changePasswordModal').on "hide.bs.modal", (e) ->
                $rootScope.editUser = null
                clean($scope)

            $('#changePasswordModal').on "show.bs.modal", (e) ->
                setEditUser $rootScope, $scope, CurrentUser
                $scope.$apply()

            $('#changePasswordModal').on "shown.bs.modal", (e) ->
                $('[autofocus]', this).focus()

            $('#changePasswordModal').keypress (e) ->
                if e.which is ENTER
                    $('#changePasswordModal form').submit()

            $scope.changePassword = (name, password, confirmed) ->
                err = Validator.validatePassword password, confirmed
                if err?
                    $scope.error = err.message
                    return
                $scope.error = null
                sendUpdateUserMessage $scope.name, password, ServerConnector,
                    () ->
                        $('#changePasswordModal').modal("hide")
                    ,
                    () ->
                        $scope.error = "Password change failed"


        setEditUser = (rootScope, scope, CurrentUser) ->
            if not rootScope.editUser?
                CurrentUser.get (user) =>
                    scope.name = user.name
            else
                scope.name = rootScope.editUser.Name

        clean = (scope) =>
            scope.password = ''
            scope.passwordConfirm = ''
            scope.error = ""

        sendUpdateUserMessage = (username, password, ServerConnector, onSucces, onError) ->
            data =
                name: username
                password: password
            ServerConnector.updateUser data, onSucces, onError

