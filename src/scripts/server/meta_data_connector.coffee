CONST = require("./config").Const
zmq = require("zmq")
fs = require("fs")
protobuf = require("node-protobuf")
proto_metadata = new protobuf(fs.readFileSync("proto/meta_data.pb.desc"))
log = require("loglevel")
require('source-map-support').install()
log.setLevel 'debug'

class MetadataConnector
    socket: null
    onMetadata: null

    onMessage: (data) =>
        metadata = proto_metadata.parse data, 'virtdb.interface.pb.MetaData'
        @onMetadata metadata
        return

    constructor: () ->
        @socket = zmq.socket('req')
        @socket.on "message", @onMessage

    connect: (address) =>
        @socket.connect(address)

    getMetadata: (schema, regexp, @onMetadata) =>
        request =
            Name: regexp
            Schema: schema
        @socket.send proto_metadata.serialize request, "virtdb.interface.pb.MetaDataRequest"

module.exports = MetadataConnector
