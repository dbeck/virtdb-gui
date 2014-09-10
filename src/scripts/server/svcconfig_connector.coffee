CONST = require("./config").Const
zmq = require("zmq")
fs = require("fs")
protobuf = require("node-protobuf")
log = require("loglevel")
require('source-map-support').install()

log.setLevel 'debug'
proto_service_config = new protobuf(fs.readFileSync("proto/svc_config.pb.desc"))

class ServiceConfig
    instance: null
    @getInstance: () ->
        @instance ?= new ServiceConfigConnector


    class ServiceConfigConnector
        reqrepSocket: null
        pubsubSocket: null
        endpoints: []
        onEndpointsReady: null
        serviceConfigConnections: []

        constructor: () ->
            @reqrepSocket = zmq.socket('req')
            @reqrepSocket.on "message", @_onMessage
            @_connect()
            @_requestEndpoints()

        getAddresses: (name) =>
            addresses = {}
            for endpoint in @endpoints when endpoint.Name is name
                addresses[endpoint.SvcType] = {} unless addresses.hasOwnProperty endpoint.SvcType
                for conn in endpoint.Connections
                    addresses[endpoint.SvcType][conn.Type] = conn.Address
            return addresses

        getEndpoints: () ->
            @endpoints

        _onMessage: (reply) =>
            @endpoints = (proto_service_config.parse reply, 'virtdb.interface.pb.Endpoint').Endpoints
            @serviceConfigConnections = endpoint.Connections for endpoint in @endpoints when endpoint.Name is "svc_config"
            @_subscribeEndpoints() unless @pubsubSocket
            return

        _connect: =>
            @reqrepSocket.connect(CONST.SVC_CONFIG_ADDRESS)


        _requestEndpoints: () =>
            endpointMessage =
                Endpoints: [
                    Name: "virtdb-gui"
                    SvcType: 'NONE'
                ]

            @reqrepSocket.send proto_service_config.serialize endpointMessage, "virtdb.interface.pb.Endpoint"
            return

        _onPublishedMessage: (channelId, message) =>
            data = (proto_service_config.parse message, 'virtdb.interface.pb.Endpoint')
            for new_endpoint in data.Endpoints
                for endpoint in @endpoints
                    if endpoint.Name == new_endpoint.Name and endpoint.SvcType == new_endpoint.SvcType
                        @endpoints.splice @endpoints.indexOf(endpoint), 1
                        break
                @endpoints = @endpoints.concat new_endpoint

        _subscribeEndpoints: () =>
            @pubsubSocket = zmq.socket('sub')
            @pubsubSocket.on "message", @_onPublishedMessage
            for connection in @serviceConfigConnections when connection.Type is 'PUB_SUB'
                for address in connection.Address
                    try
                        @pubsubSocket.connect address
                    catch ex
                        continue
                    @pubsubSocket.subscribe ''
                    break

module.exports = ServiceConfig
