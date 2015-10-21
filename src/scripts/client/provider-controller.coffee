app = require './virtdb-app.js'
module.exports = app.controller 'ProviderController',
    class ProviderController
        constructor: ($scope, ServerConnector) ->
            @$scope = $scope
            @ServerConnector = ServerConnector
            @providers = []
            @getDataProviders()

        getDataProviders: () =>
            @ServerConnector.getDataProviders(
                (data) =>
                    @providers = data
                    @providers.sort()
                    @selectProvider @providers[0]
            )

        selectProvider: (provider) =>
            @$scope.$parent.selectedProvider = provider

        isSelected: (provider) =>
            provider is @$scope.$parent.selectedProvider
