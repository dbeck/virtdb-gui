VirtDBConnector = require "virtdb-connector"
Const = VirtDBConnector.Const

class Endpoints

    @_endpoints = {}

    @getColumnAddress: (name) =>
        return @_findAddresses name, Const.ENDPOINT_TYPE.COLUMN, Const.SOCKET_TYPE.PUB_SUB
    
    @getMetadataAddress: (name) =>
        return @_findAddresses name, Const.ENDPOINT_TYPE.META_DATA, Const.SOCKET_TYPE.REQ_REP

    @getQueryAddress: (name) =>
        return @_findAddresses name, Const.ENDPOINT_TYPE.QUERY, Const.SOCKET_TYPE.PUSH_PULL
    
    @getDbConfigAddress: (name) =>
        return @_findAddresses name, Const.ENDPOINT_TYPE.DB_CONFIG, Const.SOCKET_TYPE.PUSH_PULL
    
    @getDbConfigQueryAddress: (name) =>
        return @_findAddresses name, Const.ENDPOINT_TYPE.DB_CONFIG_QUERY, Const.SOCKET_TYPE.REQ_REP
    
    @getLogRecordAddress: =>
        return @_findAddresses Const.DIAG_SERVICE, Const.ENDPOINT_TYPE.LOG_RECORD, Const.SOCKET_TYPE.PUB_SUB

    @getConfigServiceAddress: =>
        return @_findAddresses Const.CONFIG_SERVICE, Const.ENDPOINT_TYPE.CONFIG, Const.SOCKET_TYPE.REQ_REP

    @getDataProviders: =>
        providers = []
        for endpointName, endpoint of @_endpoints
            services = Object.keys endpoint
            if (Const.ENDPOINT_TYPE.META_DATA in services) and (Const.ENDPOINT_TYPE.COLUMN in services) and (Const.ENDPOINT_TYPE.QUERY in services)
                providers.push endpointName
        return providers

    @onEndpoint: (name, serviceType, socketType, addresses) =>
        @_endpoints[name] ?= {}
        @_endpoints[name][serviceType] ?= {}
        @_endpoints[name][serviceType][socketType] = addresses

        if @_endpoints[name][serviceType][socketType]?.length is 0
            delete @_endpoints[name][serviceType][socketType]
            if Object.keys(@_endpoints[name][serviceType]).length is 0
                delete @_endpoints[name][serviceType]
                if Object.keys(@_endpoints[name]).length is 0
                    delete @_endpoints[name]

    @getCompleteEndpointList: () =>
        return @_endpoints

    @_findAddresses: (name, serviceType, socketType) =>
        addresses = @_endpoints?[name]?[serviceType]?[socketType]
        if not addresses?
            return []
        return addresses

    @addOwnEndpoint: (name) =>
        @_endpoints[name] = {}

module.exports = Endpoints
