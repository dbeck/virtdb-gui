require("source-map-support").install()
zmq = require "zmq"
Proto = require "virtdb-proto"
VirtDBConnector = require "virtdb-connector"
Const = VirtDBConnector.Const
log = VirtDBConnector.log
V_ = log.Variable

serviceConfigProto = Proto.service_config

class ConfigServiceConnector

    _reqRepSocket: null
    _onConfig: null
    _addresses: null

    @createInstance: (addresses) =>
        return new ConfigServiceConnector addresses

    constructor: (@_addresses) ->
        @_reqRepSocket = zmq.socket(Const.ZMQ_REQ)
        @_reqRepSocket.on "message", @_onMessage
        @_connect()

    close: =>
        for address in @_addresses
            @_reqRepSocket.disconnect address
        @_reqRepSocket.close()
        @_reqRepSocket = null

    getConfig: (component, readyCallback) =>
        try
            @_onConfig = readyCallback
            configReq =
                Name: component
            log.debug "sending config request message:", V_(configReq)
            @_reqRepSocket.send serviceConfigProto.serialize configReq, "virtdb.interface.pb.Config"
            VirtDBConnector.MonitoringService.bumpStatistic "Config request sent"
        catch ex
            log.error V_(ex)
            throw ex

    sendConfig: (config) =>
        try
            log.debug "sending config to the config service:", V_(config)
            @_reqRepSocket.send serviceConfigProto.serialize config, "virtdb.interface.pb.Config"
            VirtDBConnector.MonitoringService.bumpStatistic "Config request sent"
        catch ex
            log.error V_(ex)
            throw ex

    _onMessage: (message) =>
        try
            try
                configMessage = serviceConfigProto.parse message, "virtdb.interface.pb.Config"
            catch ex
                VirtDBConnector.MonitoringService.requestError Const.CONFIG_SERVICE, Const.REQUEST_ERROR.INVALID_REQUEST, ex.toString()
                throw ex
            log.debug "got config message: ", V_(configMessage)
            if @_onConfig?
                @_onConfig configMessage
            return
        catch ex
            log.error V_(ex)
            throw ex

    _connect: =>
        try
            for addr in @_addresses
                @_reqRepSocket.connect addr
        catch ex
            log.error V_(ex)
            throw ex

module.exports = ConfigServiceConnector
