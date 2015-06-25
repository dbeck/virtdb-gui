app = require './virtdb-app.js'
ServerConnector = require './server-connector'
CurrentUser = require './current-user'
Validator = require './validator'

module.exports = app.controller 'ChangeUserPassword',
    class ChangeUserPassword
        constructor: ($scope, ServerConnector, $rootScope, CurrentUser, Validator) ->
            @$rootScope = $rootScope
            @$scope = $scope
            @Validator = Validator
            @CurrentUser = CurrentUser
            @ServerConnector = ServerConnector

            $('#change-password-modal').on "hide.bs.modal", (e) =>
                @$rootScope.editUser = null

            $('#change-password-modal').on "show.bs.modal", (e) =>
                @clean()
                @setEditUser()
                @$scope.$apply()

        setEditUser: =>
            console.log @$rootScope.editUser
            if not @$rootScope.editUser?
                @CurrentUser.get (user) =>
                    @$scope.name = user.name
            else
                @$scope.name = @$rootScope.editUser.Name

        changePassword: =>
            err = @Validator.validatePassword @$scope.editUserPass1, @$scope.editUserPass2
            if err?
                @$scope.error = err.message
                return
            @$scope.error = null
            @sendUpdateUserMessage()

        sendUpdateUserMessage: =>
            data =
                name: @$scope.name
                password: @$scope.editUserPass1
            @ServerConnector.updateUser data, @finishUpdate

        clean: =>
            @$scope.editUserPass1 = ""
            @$scope.editUserPass2 = ""
            @$scope.error = ""

        finishUpdate: =>
            $('#change-password-modal').modal("hide")

