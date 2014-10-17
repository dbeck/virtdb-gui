zmq = require "zmq"
fs = require "fs"
protobuf = require "node-protobuf"
log = require "loglevel"
Const = (require "virtdb-connector").Constants

require("source-map-support").install()
log.setLevel "debug"

serviceConfigProto = new protobuf(fs.readFileSync("common/proto/svc_config.pb.desc"))

class EndpointService

    instance: null
    address: null

    @getInstance: () =>
        @instance ?= new EndpointServiceConnector(@address)

    @reset: () =>
        @instance = null

    @setAddress: (@address) =>

    class EndpointServiceConnector
        reqrepSocket: null
        pubsubSocket: null
        endpoints: []
        serviceConfigConnections: []
        name: null
        address: null

        constructor: (@address) ->
            @reqrepSocket = zmq.socket(Const.ZMQ_REQ)
            @reqrepSocket.on "message", @_onMessage
            @connect()
            @_requestEndpoints()

        getComponentAddresses: (name) =>
            addresses = {}
            for endpoint in @endpoints when endpoint.Name is name
                addresses[endpoint.SvcType] ?= {}
                for conn in endpoint.Connections
                    addresses[endpoint.SvcType][conn.Type] = conn.Address
            return addresses

        getConfigServiceAddresses: () =>
            for endpoint in @endpoints
                for conn in endpoint.Connections
                    if @address in conn.Address
                        @name = endpoint.Name
                        break
            return @getComponentAddresses(@name)

        getEndpoints: () =>
            @endpoints

        getComponents: () =>
            components = []
            for endpoint in @endpoints
                if endpoint.Name not in components
                    components.push endpoint.Name
            return components

        connect: =>
            try
                @reqrepSocket.connect(@address)
                log.debug "Connected to the endpoint service!"
            catch ex
                log.error "Error during connecting to endpoint service!", ex

        _onMessage: (reply) =>
            @endpoints = (serviceConfigProto.parse reply, "virtdb.interface.pb.Endpoint").Endpoints
            @_subscribeEndpoints() unless @pubsubSocket?
            return

        _requestEndpoints: () =>
            endpointMessage =
                Endpoints: [
                    Name: ""
                    SvcType: Const.ENDPOINT_TYPE.NONE
                ]

            @reqrepSocket.send serviceConfigProto.serialize endpointMessage, "virtdb.interface.pb.Endpoint"
            return

        _onPublishedMessage: (channelId, message) =>
            data = serviceConfigProto.parse message, "virtdb.interface.pb.Endpoint"
            log.debug "Got published message from endpoint service."
            log.debug "channel:", channelId.toString()
            log.debug "data:", data
            for newEndpoint in data.Endpoints
                for endpoint in @endpoints
                    if endpoint.Name == newEndpoint.Name and endpoint.SvcType == newEndpoint.SvcType
                        @endpoints.splice @endpoints.indexOf(endpoint), 1
                        break
                @endpoints = @endpoints.concat newEndpoint

        _subscribeEndpoints: () =>
            try
                @pubsubSocket = zmq.socket(Const.ZMQ_SUB)
                @pubsubSocket.on "message", @_onPublishedMessage
                connections = @getConfigServiceAddresses()
                address = connections[Const.ENDPOINT_TYPE.ENDPOINT][Const.SOCKET_TYPE.PUB_SUB][0]
                @pubsubSocket.connect address
                @pubsubSocket.subscribe Const.EVERY_CHANNEL
                log.debug "Subscribed to endpoint service", address
            catch ex
                log.debug "Couldn't subscribe to endpoint service", ex

module.exports = EndpointService
