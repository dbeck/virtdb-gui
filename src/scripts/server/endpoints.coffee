VirtDBConnector = require "virtdb-connector"
Const = VirtDBConnector.Constants

class Endpoints

    @_endpoints = {}

    @getColumnAddress: (name) =>
        return @_endpoints?[name]?[Const.ENDPOINT_TYPE.COLUMN]?[Const.SOCKET_TYPE.PUB_SUB]
    
    @getMetadataAddress: (name) =>
        return @_endpoints?[name]?[Const.ENDPOINT_TYPE.META_DATA]?[Const.SOCKET_TYPE.REQ_REP]
    
    @getQueryAddress: (name) =>
        return @_endpoints?[name]?[Const.ENDPOINT_TYPE.QUERY]?[Const.SOCKET_TYPE.PUSH_PULL]
    
    @getDbConfigAddress: (name) =>
        return @_endpoints?[name]?[Const.ENDPOINT_TYPE.DB_CONFIG]?[Const.SOCKET_TYPE.REQ_REP]
    
    @getLogRecordAddress: =>
        return @_endpoints?[Const.DIAG_SERVICE]?[Const.ENDPOINT_TYPE.LOG_RECORD]?[Const.SOCKET_TYPE.PUSH_PULL]

    @getConfigServiceAddress: =>
        return @_endpoints?[Const.CONFIG_SERVICE]?[Const.ENDPOINT_TYPE.CONFIG]?[Const.SOCKET_TYPE.REQ_REP]

    @getDataProviders: =>
        #TODO
        return 

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


module.exports = Endpoints
