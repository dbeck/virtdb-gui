zmq = require "zmq"
Const = (require "virtdb-connector").Constants
protobuf = require "node-protobuf"
log = (require "virtdb-connector").log
V_ = log.Variable

require("source-map-support").install()

MetaDataProto = new protobuf(fs.readFileSync("common/proto/meta_data.pb.desc"))

class MetadataConnection

    _metadataAddress: null
    _metadataSocket: null

    _onMetadata: null

    constructor: (@_metadataAddress) ->

    getMetadata: (metadataRequest, onMetaData) =>
        @_initMetadataSocket()
        try
            log.trace "sending MetaDataRequest message", V_(metadataRequest)
            @_metadataSocket.send MetaDataProto.serialize metadataRequest, "virtdb.interface.pb.MetaDataRequest"
        catch ex
            log.error V_(ex)
            throw ex

    _initMetadataSocket: =>
        try
            @_metadataSocket = zmq.socket(Const.ZMQ_REQ)
            @_metadataSocket.connect(@_metadataAddress)
            @_metaDataSocket.on "message", @_onMetadataMessage
        catch ex
            log.error V_(ex)
            throw ex

    _onMetadataMessage: (message) =>
        try
            metadata = MetaDataProto.parse message, "virtdb.interface.pb.MetaData"
            log.trace "got metadata", V_(schema), V_(table)
            @_onMetadata metadata
            return
        catch ex
            log.error V_(ex)
            throw ex

module.exports = MetadataDataConnection
