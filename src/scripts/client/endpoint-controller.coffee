app = require './virtdb-app.js'

module.exports = app.controller 'EndpointController',
class EndpointController
    endpoints: null

    constructor: (CurrentUser, ServerConnector, $scope, $rootScope) ->
        @ServerConnector = ServerConnector
        @$scope = $scope
        @$rootScope = $rootScope
        @endpoints = []
        @requestEndpoints()
        @setupWatches()
        $scope.isNumber = (item) ->
            type = item?.Data?.Value?.Type
            return type in ['UINT32', 'UINT64', 'INT32', 'INT64']
        $scope.isPassword = (item) ->
            value = item?.Data?.Value?.Value?[0]
            return value? and value.toString().toLowerCase() == 'password'
        $scope.isRequired = (item) ->
            return item?.Data?.Required?.Value?[0]
        $scope.isRange = (item) ->
            minimum = item?.Data?.Minimum?.Value?[0]?
            maximum = item?.Data?.Maximum?.Value?[0]?
            return minimum or maximum
        $scope.getMinimum = (item) ->
            minimum = item?.Data?.Minimum?.Value?[0]
            minimum ?= ""
            return minimum
        $scope.clearStatus = ->
            $scope.failure = false
            $scope.success = false
            $scope.saving = false
        $scope.getMaximum = (item) ->
            maximum = item?.Data?.Maximum?.Value?[0]
            maximum ?= ""
            return maximum
        $scope.clearStatus()

        CurrentUser.get (user) ->
            $scope.user = user

    setupWatches: () =>
        @$scope.$watch "selectedComponent", () =>
            @updateComponentInfo()
            @requestComponentConfig()
            @requestComponentCredential()

    requestComponentConfig: () =>
        @$scope.saving = false
        if @$scope.selectedComponent?
            @ServerConnector.getConfig { selectedComponent: @$scope.selectedComponent}, (data) =>
                @$scope.componentConfig = data

    requestComponentCredential: () =>
        if @$scope.selectedComponent?
            @ServerConnector.getCredential { selectedComponent: @$scope.selectedComponent}, (data) =>
                @$scope.credentialTemplate = data

    requestEndpoints: () =>
        @ServerConnector.getEndpoints (data) =>
            @endpoints = data
            @$scope.componentList = Object.keys data

    getComponentList: () =>
        return @endpoints.map (endpoint) ->
            endpoint.Name
        .sort()
        .filter (name, index, componentList) ->
            if index is componentList.length - 1
                return true
            return name isnt componentList[index + 1]

    updateComponentInfo: () =>
        @$scope.componentInfo = []
        for name, endpoint of @endpoints when name is @$scope.selectedComponent
            for svcType, service of endpoint
                for socketType, addresses of service
                    for addr in addresses
                        infoRow =
                            SvcType: svcType
                            SocketType: socketType
                            Address: addr
                        @$scope.componentInfo.push infoRow

    sendConfig: =>
        @$scope.saving = true
        @$scope.failure = false
        @$scope.success = false
        for item in @$scope.componentConfig
            if item.Data.Value.Type == 'BOOL' and item.Data.Value.Value[0]?.toLowerCase?() == 'false'
                item.Data.Value.Value[0] = false
            if item.Data.Value.Type == 'BOOL' and item.Data.Value.Value[0]?.toLowerCase?() == 'true'
                item.Data.Value.Value[0] = true
        @ServerConnector.setConfig
            selectedComponent: @$scope.selectedComponent
            componentConfig: @$scope.componentConfig
        , =>
            @ServerConnector.getSettings (data) =>
                @$scope.saving = false
                @$scope.success = true
                @$rootScope.Settings = data
            @requestComponentConfig()
        , =>
            @$scope.failure = true
            @requestComponentConfig()

    sendCredential: =>
        @ServerConnector.setCredential
            selectedComponent: @$scope.selectedComponent
            credentials: @$scope.credentialTemplate
        , =>
            @requestComponentCredential()
