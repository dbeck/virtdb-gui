CONST = require("./config").Const
zmq = require("zmq")
fs = require("fs")
protobuf = require("node-protobuf")
proto_metadata = new protobuf(fs.readFileSync("proto/meta_data.pb.desc"))
proto_data = new protobuf(fs.readFileSync("proto/data.pb.desc"))
log = require("loglevel")
require('source-map-support').install()
log.setLevel 'debug'
ServiceConfig = require('./svcconfig_connector')

class DataProviderConnection

    @_configService = ServiceConfig.getInstance()

    @getConnection: (provider) =>
        adresses = @_configService.getAddresses provider
        try
            metaDataAddress = adresses["META_DATA"]["REQ_REP"][0]
            columnAddress = adresses["COLUMN"]["PUB_SUB"][0]
            queryAddress = adresses["QUERY"]["PUSH_PULL"][0]
        catch ex
            log.error "Couldn't get provider addresses!"
            throw ex
        return new DataProviderConnection(metaDataAddress, columnAddress, queryAddress)

    _reqRepSocket: null
    _pushPullSocket: null
    _pubSubSocket: null

    constructor: (@metaDataAddress, @columnAddress, @queryAddress) ->

    getMetadata: (schema, regexp, withFields, onMetaData) =>

        metaDataRequest =
            Name: regexp
            Schema: schema
            WithFields: withFields

        @_reqRepSocket = zmq.socket('req')
        @_reqRepSocket.connect(@metaDataAddress)
        @_reqRepSocket.on "message", (data) =>
            metaData = proto_metadata.parse data, 'virtdb.interface.pb.MetaData'
            log.debug 'Got metadata: ', metaData
            onMetaData metaData
            return

        try
            log.debug "Sending MetaDataRequest message: " + JSON.stringify metaDataRequest
            @_reqRepSocket.send proto_metadata.serialize metaDataRequest, "virtdb.interface.pb.MetaDataRequest"
        catch e
            log.error e

    getData: (table, fields, count, onColumn) =>

        @queryId = Math.floor((Math.random() * 100000) + 1);

        query =
            QueryId: @queryId
            Table: table
            Fields: fields
            Limit: count

        @_pubSubSocket = zmq.socket('sub')
        @_pubSubSocket.connect(@columnAddress)
        @_pubSubSocket.subscribe @queryId.toString()
        @_pubSubSocket.on "message", (channel, data) =>
            log.debug 'Got column on channel: ', channel.toString()
            column = proto_data.parse data, 'virtdb.interface.pb.Column'
            log.debug 'Data: ', column
            onColumn column
            return

        @_pushPullSocket = zmq.socket('push')
        @_pushPullSocket.connect(@queryAddress)

        try
            log.debug "Sending Query message: " + JSON.stringify query
            @_pushPullSocket.send proto_data.serialize query, "virtdb.interface.pb.Query"
        catch e
            log.error e

    close: () =>
        if @_reqRepSocket?
            @_reqRepSocket.close()
        if @_pubSubSocket?
            @_pubSubSocket.close()
        if @_pushPullSocket?
            @_pushPullSocket.close()

module.exports = DataProviderConnection
