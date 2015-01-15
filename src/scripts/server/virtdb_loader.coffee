Configuration = require "./config"
ConfigService = require "./config_service"
EndpointServiceConnector = require "./endpoint_service"
DiagConnector = require "./diag_connector"
CacheHandler = require "./cache_handler"
VirtDBConnector = require "virtdb-connector"
Const = VirtDBConnector.Constants
async = require "async"

class VirtDBLoader

    @start: (startCallback) =>
        address = Configuration.getCommandLineParameter("serviceConfig")
        name = Configuration.getCommandLineParameter("name")
        async.series [
            (callback) ->
                try
                    VirtDBConnector.onAddress Const.ENDPOINT_TYPE.CONFIG, Const.SOCKET_TYPE.REQ_REP, (name, address) =>
                        console.log "Got config service address:", address
                        ConfigService.setAddress(address)
                        Configuration.init()
                    VirtDBConnector.subscribe Const.ENDPOINT_TYPE.CONFIG, Const.SOCKET_TYPE.PUB_SUB, ConfigService.onPublishedConfig, name
                    VirtDBConnector.connect(name, address)
                    callback null
                catch ex
                    callback ex
            ,
            (callback) ->
                try
                    EndpointServiceConnector.reset()
                    EndpointServiceConnector.setAddress(address)
                    async.whilst () ->
                                    EndpointServiceConnector.getInstance().getEndpoints().length == 0
                                ,
                                (cb) ->
                                    setTimeout(cb, 500)
                                ,
                                () ->
                                    callback null
            ,
            (callback) ->
                DiagConnector.connect("diag-service")
                CacheHandler.init()
                callback null
            ], (err, results) ->
                if err
                    console.error "Error happened:", err
                if startCallback?
                    startCallback()

module.exports = VirtDBLoader
