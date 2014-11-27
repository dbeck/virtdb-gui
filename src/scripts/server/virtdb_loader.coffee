ConfigService = require "./config_service"
EndpointService = require "./endpoint_service"
DiagConnector = require "./diag_connector"
VirtDBConnector = require "virtdb-connector"
Const = VirtDBConnector.Constants
Config = require "./config"
async = require "async"
log = require "loglevel"
log.setLevel "debug"
commandLine = require("nomnom").parse()
guiConfigHandler = require "./gui_config_handler"

class VirtDBLoader

    @start: (startCallback) =>
        address = commandLine["service-config"]
        name = commandLine["name"]
        guiConfigHandler.setName name
        async.series [
            (callback) ->
                try
                    VirtDBConnector.onAddress Const.ENDPOINT_TYPE.CONFIG, Const.SOCKET_TYPE.REQ_REP, (name, address) =>
                        console.log "Got config service address:", address
                        ConfigService.setAddress(address)
                        guiConfigHandler.getConfig()
                    VirtDBConnector.subscribe Const.ENDPOINT_TYPE.CONFIG, Const.SOCKET_TYPE.PUB_SUB, guiConfigHandler.onPublishedConfig, name
                    VirtDBConnector.connect(name, address)
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
            ,
            (callback) ->
                DiagConnector.connect("diag-service")
                callback null
            ], (err, results) ->
                if err
                    console.error err
                if startCallback?
                    startCallback()

module.exports = VirtDBLoader
