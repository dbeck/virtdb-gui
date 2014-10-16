ConfigService = require "./config_service"
EndpointService = require "./endpoint_service"
VirtDBConnector = require "virtdb-connector"
Const = VirtDBConnector.Constants
Config = require "./config"
async = require "async"
log = require "loglevel"
log.setLevel "debug"

class VirtDBLoader

    @startCallback: null

    @setStartCallback: (callback) =>
        @startCallback = callback

    @start: (address = Config.Values.CONFIG_SERVICE_ADDRESS) =>
        callb = @startCallback
        if address?
            Config.Values.CONFIG_SERVICE_ADDRESS = address
        async.series [
            (callback) ->
                try
                    VirtDBConnector.connect(Config.Values.GUI_ENDPOINT_NAME, address)
                    VirtDBConnector.onAddress Const.ENDPOINT_TYPE.CONFIG, Const.SOCKET_TYPE.REQ_REP, (address) =>
                        log.debug "Got config service address:", address
                        ConfigService.setAddress(address)
                    callback null
                catch ex
                    callback ex
            ,
            (callback) ->
                try
                    EndpointService.reset()
                    EndpointService.setAddress(address)
                    async.whilst () ->
                                    EndpointService.getInstance().getEndpoints().length == 0
                                ,
                                (cb) ->
                                    setTimeout(cb, 500)
                                ,
                                () ->
                                    callback null
            ], (err, results) ->
            if err
                console.error err
            callb()

module.exports = VirtDBLoader
