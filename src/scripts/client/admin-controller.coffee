app = require './virtdb-app.js'

ServerConnector = require './server-connector.js'

adminController = app.controller 'AdminController',
    ($scope, $rootScope, ServerConnector) ->
        ServerConnector.getCertificates (components) ->
            $scope.components = components
            updateWaitingCount $rootScope, $scope

        $scope.approve = approve.bind null, ServerConnector, $rootScope, $scope
        $scope.remove = remove.bind null, ServerConnector, $rootScope, $scope

countWaiting = (components) ->
    count = 0
    if components
        for component in components
            if not component.Approved
                count += 1
    return count

approve = (ServerConnector, rootScope, scope, component, authCode) ->
    ServerConnector.approveCertificate authCode, component, ->
        component.Approved = true
        console.log scope
        updateWaitingCount rootScope, scope

remove = (ServerConnector, rootScope, scope, component) ->
    ServerConnector.removeCertificate component, ->
        for c, index in scope.components
            if c is component
                scope.components.splice index, 1
        updateWaitingCount rootScope, scope

updateWaitingCount = (rootScope, scope) ->
    rootScope.waitingCertCount = countWaiting scope.components

module.exports = adminController

