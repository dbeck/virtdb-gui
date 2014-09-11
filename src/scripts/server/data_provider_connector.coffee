CONST = require("./config").Const
zmq = require("zmq")
fs = require("fs")
protobuf = require("node-protobuf")
proto_metadata = new protobuf(fs.readFileSync("proto/meta_data.pb.desc"))
proto_data = new protobuf(fs.readFileSync("proto/data.pb.desc"))
log = require("loglevel")
require('source-map-support').install()
log.setLevel 'debug'

class DataProviderConnector
    metaDataSocket: null
    columnSocket: null
    querySocket: null

    onMetaData: null
    onColumn: null
    dataColumns: null

    queryId = 0

    constructor: (metaDataAddress, columnAddress, queryAddress) ->

        #initialize meta data socket
        @metaDataSocket = zmq.socket('req')
        @metaDataSocket.on "message", @_onMetaDataMessage
        @metaDataSocket.connect(metaDataAddress)

        #initialize column data socket
        @columnSocket = zmq.socket('sub')
        @columnSocket.on "message", @_onColumnMessage
        @columnSocket.connect(columnAddress)

        #initialize data socket
        @querySocket = zmq.socket('push')
        @querySocket.connect(queryAddress)

    getMetadata: (schema, regexp, withFields, @onMetaData) =>
        request =
            Name: regexp
            Schema: schema
            WithFields: true
        try
            @metaDataSocket.send proto_metadata.serialize request, "virtdb.interface.pb.MetaDataRequest"
        catch e
            log.error e

    getData: (table, fields, count, @onColumn) =>

        @queryId = Math.floor((Math.random() * 100000) + 1);
        @columnSocket.subscribe(@queryId.toString())

        query =
            QueryId: @queryId
            Table: table
            Fields: fields
            Limit: count
        @querySocket.send proto_data.serialize query, "virtdb.interface.pb.Query"

    _onMetaDataMessage: (data) =>
        metadata = proto_metadata.parse data, 'virtdb.interface.pb.MetaData'
        @onMetaData metadata
        return

    _onColumnMessage: (channelId, data) =>
        column = proto_data.parse data, 'virtdb.interface.pb.Column'
        @onColumn column
        return


module.exports = DataProviderConnector
