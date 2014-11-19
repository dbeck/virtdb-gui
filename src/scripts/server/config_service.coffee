zmq = require "zmq"
fs = require "fs"
protobuf = require "node-protobuf"
util = require "util"
VirtDBConnector = (require "virtdb-connector")
Const = VirtDBConnector.Constants
log = VirtDBConnector.log
V_ = log.Variable

require("source-map-support").install()
log.setLevel "debug"

serviceConfigProto = new protobuf(fs.readFileSync("common/proto/svc_config.pb.desc"))

class ConfigService

    @_address: null

    @setAddress: (address) ->
        @_address = address

    @getConfig: (component, onConfig) =>
        connection = new ConfigServiceConnector(@_address)
        connection.getConfig component, onConfig

    @sendConfig: (config) =>
        connection = new ConfigServiceConnector(@_address)
        connection.sendConfig(config)

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
            try
                @_onConfig = readyCallback
                configReq =
                    Name: component
                log.debug "sending config request message:", configReq
                @_reqRepSocket.send serviceConfigProto.serialize configReq, "virtdb.interface.pb.Config"
            catch ex
                log.error V_(ex)
                throw ex

        sendConfig: (config) =>
            try
                @_reqRepSocket.send serviceConfigProto.serialize config, "virtdb.interface.pb.Config"
                log.debug "config sent to the config service:", V_(config)
            catch ex
                log.error V_(ex)
                throw ex

        _onMessage: (message) =>
            try
                configMessage = serviceConfigProto.parse message, "virtdb.interface.pb.Config"
                log.trace "got config message: ", (util.inspect configMessage, {depth: null})
                if @_onConfig?
                    @_onConfig configMessage
                return
            catch ex
                log.error V_(ex)
                throw ex

        _connect: =>
            try
                @_reqRepSocket.connect(@_address)
            catch ex
                log.error V_(ex)
                throw ex

module.exports = ConfigService
