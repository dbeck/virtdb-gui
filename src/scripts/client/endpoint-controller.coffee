app = angular.module 'virtdb'
app.controller 'EndpointController',
class EndpointController
    endpoints: null

    constructor: (ServerConnector, $http, $scope, $rootScope) ->
        @ServerConnector = ServerConnector
        @$http = $http
        @$scope = $scope
        @$rootScope = $rootScope
        @endpoints = []
        @requestEndpoints()
        @setupWatches()

    setupWatches: () =>
        @$scope.$watch "selectedComponent", () =>
            @updateComponentInfo()
            @requestComponentConfig()

    requestComponentConfig: () =>
        if @$scope.selectedComponent?
            url = "/api/get_config/" + @$scope.selectedComponent
            @$http.get(url).success (data) =>
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
        @$http.post("/api/set_config/" + @$scope.selectedComponent, @$scope.componentConfig)
