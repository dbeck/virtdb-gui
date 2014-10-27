app = angular.module 'virtdb'
app.controller 'EndpointController',
class EndpointController
    endpoints: null

    constructor: (@ServerConnector, @$http, @$scope, @$rootScope) ->
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
                console.log data
                @$scope.componentConfig = data
        return

    requestEndpoints: () =>
        @ServerConnector.getEndpoints(
            (data) =>
                @endpoints = data
                @$scope.componentList = @getComponentList()
        )

    getComponentList: () =>
        components = []
        for ep in @endpoints
            if ep.Name not in components
                components.push ep.Name
        return components

    updateComponentInfo: () =>
        @$scope.componentInfo = []
        for ep in @endpoints when ep.Name is @$scope.selectedComponent
            for connection in ep.Connections
                for addr in connection.Address
                    infoRow =
                        SvcType: ep.SvcType
                        SocketType: connection.Type
                        Address: addr
                    @$scope.componentInfo.push infoRow
        return

    sendConfig: () =>
        @$http.post("/api/set_config/" + @$scope.selectedComponent, @$scope.componentConfig)
