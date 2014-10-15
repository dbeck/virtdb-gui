zmq = require "zmq"
fs = require "fs"
protobuf = require "node-protobuf"
log = require "loglevel"
util = require "util"
VirtDBConnector = (require "virtdb-connector")
Const = VirtDBConnector.Constants
# Convert = require "./convert"

require("source-map-support").install()
log.setLevel "debug"

serviceConfigProto = new protobuf(fs.readFileSync("common/proto/svc_config.pb.desc"))

class ConfigService

    @_address: null

    @setAddress: (address) ->
        @_address = address

    @getConfig: (component, onConfig) =>
        try
            connection = new ConfigServiceConnector(@_address)
            connection.getConfig component, onConfig
        catch ex
            log.error "Couldn't get config of component:", component, ex
            onConfig {}

    @sendConfig: (config) =>
        try
            connection = new ConfigServiceConnector(@_address)
            connection.sendConfig(config)
        catch ex
            log.error "Couldn't send config of component:", component, ex

    # @convertTemplateToOld: (source) ->
    #     Convert.TemplateToOld source
    #
    # @convertTemplateToNew: (source) ->
    #     Convert.TemplateToNew source
    #
    # @convertToOld: (source) ->
    #     Convert.ToOld source
    #
    # @convertToNew: (source) ->
    #     Convert.ToNew source

    class ConfigServiceConnector

        _reqRepSocket: null
        _onConfig: null
        _address: null

        constructor: (@_address) ->
            @configs = {}
            @_reqRepSocket = zmq.socket(Const.ZMQ_REQ)
            @_reqRepSocket.on "message", @_onMessage
            @_connect()

        getConfig: (component, readyCallback) =>
            @_onConfig = readyCallback
            configReq =
                Name: component
            log.debug "Sending config request message:", configReq
            @_reqRepSocket.send serviceConfigProto.serialize configReq, "virtdb.interface.pb.Config"

        sendConfig: (config) =>
            try
                @_reqRepSocket.send serviceConfigProto.serialize config, "virtdb.interface.pb.Config"
                log.debug "Config sent to the config service:", util.inspect config, {depth: null}
            catch ex
                log.error "Error during sending config!", ex

        _onMessage: (message) =>
            configMessage = serviceConfigProto.parse message, "virtdb.interface.pb.Config"
            log.debug "Got config message: ", (util.inspect configMessage, {depth: null})
            if @_onConfig?
                @_onConfig configMessage
            return

        _connect: =>
            try
                @_reqRepSocket.connect(@_address)
                log.debug "Connected to the config service!"
            catch ex
                log.error "Error during connecting to config service!", ex, @_address
                throw ex

module.exports = ConfigService
