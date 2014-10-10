EndpointService = (require "virtdb-connector").EndpointService
ConfigService = (require "virtdb-connector").ConfigService
VirtDBConnector = (require "virtdb-connector")
Config = require "./config"
async = require "async"

class VirtDBLoader

    @start = () =>
        async.series [
            (callback) ->
                try
                    VirtDBConnector.connect(Config.Values.GUI_ENDPOINT_NAME, Config.Values.CONFIG_SERVICE_ADDRESS)
                    callback null
                catch ex
                    callback ex
            ,
            (callback) ->
                try
                    EndpointService.reset()
                    EndpointService.setConnectionData(Config.Values.CONFIG_SERVICE_NAME, Config.Values.CONFIG_SERVICE_ADDRESS)
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
                try
                    ConfigService.getInstance()
                    callback null
                catch ex
                    callback ex

        ], (err, results) ->
            if err
                console.error err

module.exports = VirtDBLoader
