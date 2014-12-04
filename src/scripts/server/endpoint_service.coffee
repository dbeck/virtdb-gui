require("source-map-support").install()
zmq = require "zmq"
fs = require "fs"
protobuf = require "node-protobuf"
log = require "loglevel"
VirtDBConnector = require "virtdb-connector"
Const = VirtDBConnector.Constants
log = VirtDBConnector.log
V_ = log.Variable
Config = require "./config"

serviceConfigProto = new protobuf(fs.readFileSync("common/proto/svc_config.pb.desc"))

class EndpointService

    _instance: null
    _address: null

    @getInstance: () =>
        @_instance ?= new EndpointServiceConnector(@_address)

    @reset: () =>
        @_instance = null

    @setAddress: (@_address) =>

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

        getServiceConfigAddresses: () =>
            for endpoint in @endpoints
                for conn in endpoint.Connections
                    if @address in conn.Address
                        @name = endpoint.Name
                        return @getComponentAddresses(@name)

        getEndpoints: () =>
            return @endpoints

        getComponents: () =>
            components = []
            for endpoint in @endpoints
                if endpoint.Name not in components
                    components.push endpoint.Name
            return components

        connect: =>
            try
                @reqrepSocket.connect(@address)
            catch ex
                console.error "Error during connecting to endpoint service!", ex

        _onMessage: (reply) =>
            @endpoints = (serviceConfigProto.parse reply, "virtdb.interface.pb.Endpoint").Endpoints
            @endpoints.push {Name: Config.getCommandLineParameter("name")}
            @_subscribeEndpoints() unless @pubsubSocket?
            return

        _requestEndpoints: () =>
            try
                endpointMessage =
                    Endpoints: [
                        Name: ""
                        SvcType: Const.ENDPOINT_TYPE.NONE
                    ]
                @reqrepSocket.send serviceConfigProto.serialize endpointMessage, "virtdb.interface.pb.Endpoint"
            catch ex
                console.error "Error during requesting endpoint list!"
            return

        _handlePublishedMessage: (data) =>
            console.log data
            for newEndpoint in data.Endpoints
                for endpoint in @endpoints
                    if endpoint.Name == newEndpoint.Name and endpoint.SvcType == newEndpoint.SvcType
                        @endpoints.splice @endpoints.indexOf(endpoint), 1
                        break
                @endpoints = @endpoints.push newEndpoint

        _onPublishedMessage: (channelId, message) =>
            try
                data = serviceConfigProto.parse message, "virtdb.interface.pb.Endpoint"
                log.debug "got published message from endpoint service.", V_(channelId)
                @_handlePublishedMessage data
            catch ex
                log.error V_(ex)

        _subscribeEndpoints: () =>
            try
                @pubsubSocket = zmq.socket(Const.ZMQ_SUB)
                @pubsubSocket.on "message", @_onPublishedMessage
                connections = @getServiceConfigAddresses()
                address = connections[Const.ENDPOINT_TYPE.ENDPOINT][Const.SOCKET_TYPE.PUB_SUB][0]
                @pubsubSocket.connect address
                @pubsubSocket.subscribe Const.EVERY_CHANNEL
                log.trace "subscribed to endpoint service", V_(address)
            catch ex
                log.trace "couldn't subscribe to endpoint service", V_(ex)

module.exports = EndpointService
