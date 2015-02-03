zmq = require "zmq"
Const = (require "virtdb-connector").Constants
log = (require "virtdb-connector").log
V_ = log.Variable
Proto = require "virtdb-proto"

require("source-map-support").install()

MetaDataProto = Proto.meta_data

class MetadataConnection

    _metadataAddresses: null
    _metadataSocket: null

    _onMetadata: null

    constructor: (@_metadataAddresses) ->

    getMetadata: (metadataRequest, onMetaData) =>
        @_onMetadata = onMetaData
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
            for addr in @_metadataAddresses
                @_metadataSocket.connect addr
            @_metadataSocket.on "message", @_onMetadataMessage
        catch ex
            log.error V_(ex)
            throw ex

    _onMetadataMessage: (message) =>
        try
            metadata = MetaDataProto.parse message, "virtdb.interface.pb.MetaData"
            @_onMetadata metadata
            return
        catch ex
            log.error V_(ex)
            throw ex

    @createInstance: (addresses) =>
        return new MetadataConnection addresses

module.exports = MetadataConnection
