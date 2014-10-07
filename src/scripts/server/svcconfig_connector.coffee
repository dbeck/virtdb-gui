zmq = require "zmq"
fs = require "fs"
protobuf = require "node-protobuf"
log = require "loglevel"
Config = require "./config"
Const = require "./constants"

require("source-map-support").install()
log.setLevel "debug"

serviceConfigProto = new protobuf(fs.readFileSync("common/proto/svc_config.pb.desc"))

class ServiceConfig
    instance: null
    @getInstance: () ->
        @instance ?= new ServiceConfigConnector

    @reset: () ->
        @instance = null


    class ServiceConfigConnector
        reqrepSocket: null
        pubsubSocket: null
        endpoints: []
        onEndpointsReady: null
        serviceConfigConnections: []

        constructor: () ->
            @reqrepSocket = zmq.socket(Const.ZMQ_REQ)
            @reqrepSocket.on "message", @_onMessage
            @connect()
            @_requestEndpoints()

        getAddresses: (name) =>
            addresses = {}
            for endpoint in @endpoints when endpoint.Name is name
                addresses[endpoint.SvcType] ?= {}
                for conn in endpoint.Connections
                    addresses[endpoint.SvcType][conn.Type] = conn.Address
            return addresses

        getEndpoints: () =>
            @endpoints

        connect: =>
            try
                @reqrepSocket.connect(Config.Values.CONFIG_SERVICE_ADDRESS)
            catch ex
                log.error "Error during connect: #{ex}"
            log.debug "Connected to the service config!"

        _onMessage: (reply) =>
            @endpoints = (serviceConfigProto.parse reply, "virtdb.interface.pb.Endpoint").Endpoints
            @serviceConfigConnections = endpoint.Connections for endpoint in @endpoints when endpoint.Name is Config.Values.CONFIG_SERVICE_NAME
            @_subscribeEndpoints() unless @pubsubSocket
            return

        _requestEndpoints: () =>
            endpointMessage =
                Endpoints: [
                    Name: Config.Values.GUI_ENDPOINT_NAME
                    SvcType: Const.ENDPOINT_TYPE.NONE
                ]

            @reqrepSocket.send serviceConfigProto.serialize endpointMessage, "virtdb.interface.pb.Endpoint"
            return

        _onPublishedMessage: (channelId, message) =>
            data = (serviceConfigProto.parse message, "virtdb.interface.pb.Endpoint")
            for newEndpoint in data.Endpoints
                for endpoint in @endpoints
                    if endpoint.Name == newEndpoint.Name and endpoint.SvcType == newEndpoint.SvcType
                        @endpoints.splice @endpoints.indexOf(endpoint), 1
                        break
                @endpoints = @endpoints.concat newEndpoint

        _subscribeEndpoints: () =>
            @pubsubSocket = zmq.socket(Const.ZMQ_SUB)
            @pubsubSocket.on "message", @_onPublishedMessage
            for connection in @serviceConfigConnections when connection.Type is Const.SOCKET_TYPE.PUB_SUB
                for address in connection.Address
                    try
                        @pubsubSocket.connect address
                    catch ex
                        continue
                    @pubsubSocket.subscribe Const.EVERY_CHANNEL
                    break

module.exports = ServiceConfig
