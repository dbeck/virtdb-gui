app = require './virtdb-app.js'

ServerConnector = require './server-connector.js'
CurrentUser = require './current-user'

adminController = app.controller 'AdminController',
    ($scope, $rootScope, ServerConnector, CurrentUser) ->
        CurrentUser.get (user) ->
            $scope.user = user
        updateCertificates ServerConnector, $scope, $rootScope
        $scope.approve = approve.bind null, ServerConnector, $rootScope, $scope
        $scope.remove = remove.bind null, ServerConnector, $rootScope, $scope
        $scope.logout = CurrentUser.logout

updateCertificates = (connector, scope, rootScope) ->
    connector.getCertificates (components) ->
        scope.components = components
        updateWaitingCount rootScope, scope

countWaiting = (components) ->
    count = 0
    if components
        for component in components
            if not component.Approved
                count += 1
    return count

approve = (ServerConnector, rootScope, scope, component, authCode) ->
    ServerConnector.approveCertificate authCode, component, ->
        updateCertificates ServerConnector, scope, rootScope

remove = (ServerConnector, rootScope, scope, component) ->
    ServerConnector.removeCertificate component, ->
        for c, index in scope.components
            if c is component
                scope.components.splice index, 1
        updateWaitingCount rootScope, scope

updateWaitingCount = (rootScope, scope) ->
    rootScope.waitingCertCount = countWaiting scope.components

module.exports = adminController

