app = require './virtdb-app.js'
module.exports = app.controller 'EndpointController',
class EndpointController
    endpoints: null

    constructor: (ServerConnector, $scope, $rootScope) ->
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
        $scope.getMaximum = (item) ->
            maximum = item?.Data?.Maximum?.Value?[0]
            maximum ?= ""
            return maximum

    setupWatches: () =>
        @$scope.$watch "selectedComponent", () =>
            @updateComponentInfo()
            @requestComponentConfig()

    requestComponentConfig: () =>
        if @$scope.selectedComponent?
            @ServerConnector.getConfig { selectedComponent: @$scope.selectedComponent}, (data) =>
                @$scope.componentConfig = data
        return

    requestEndpoints: () =>
        @ServerConnector.getEndpoints(
            (data) =>
                @endpoints = data
                @$scope.componentList = Object.keys data
        )

    getComponentList: () =>
        components = []
        for ep in @endpoints
            if ep.Name not in components
                components.push ep.Name
        return components

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

        # for ep in @endpoints when ep.Name is @$scope.selectedComponent
        #     if ep.Connections?
        #         for connection in ep.Connections
        #             for addr in connection.Address
        #                 infoRow =
        #                     SvcType: ep.SvcType
        #                     SocketType: connection.Type
        #                     Address: addr
        #                 @$scope.componentInfo.push infoRow
        return

    sendConfig: () =>
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
                @$rootScope.Settings = data
            @requestComponentConfig()
        , @requestComponentConfig
