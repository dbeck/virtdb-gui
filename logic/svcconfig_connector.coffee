CONST = require("./config").Const
zmq = require("zmq")
fs = require("fs")
protobuf = require("node-protobuf")
proto_service_config = new protobuf(fs.readFileSync("proto/svc_config.pb.desc"))
log = require("loglevel")
log.setLevel 'debug'

class ServiceConfigConnector
    socket: null
    onEndpointsReceived: null

    onMessage: (reply) =>
        endpoints = proto_service_config.parse reply, 'virtdb.interface.pb.Endpoint'
        @onEndpointsReceived endpoints
        return

    constructor: () ->
        @socket = zmq.socket('req')
        @socket.on "message", @onMessage

    connect: =>
        @socket.connect(CONST.SVC_CONFIG_ADDRESS)

    getEndpoints: (onEndpointsReceived) =>
        @onEndpointsReceived = onEndpointsReceived
        endpoint = {}
        endpoint.Endpoints = []
        @socket.send proto_service_config.serialize endpoint, "virtdb.interface.pb.Endpoint"

module.exports = ServiceConfigConnector
