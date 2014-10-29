zmq = require "zmq"
fs = require "fs"
protobuf = require "node-protobuf"
log = require "loglevel"

Config = require "./config"
Const = (require "virtdb-connector").Constants
FieldData = require "./fieldData"
EndpointService = require "./endpoint_service"

require("source-map-support").install()
log.setLevel "debug"

dbConfigProto = new protobuf(fs.readFileSync("common/proto/db_config.pb.desc"))

class DBConfig

    @addTable: (provider, tableMeta) =>
        if not tableMeta?
            log.error "Couldn't add table to the db config due to a problem with the meta data:", tableMeta
            return

        connection = DBConfigConnection.getConnection(Config.Values.DB_CONFIG_SERVICE)
        try
            connection.sendServerConfig provider, tableMeta
            log.debug "Table added to the db config:", tableMeta.Name, provider
        catch ex
            return

    @getTables: (provider, onReady) =>
        connection = DBConfigConnection.getConnection(Config.Values.DB_CONFIG_SERVICE)
        try
            connection.getTables provider, (msg) =>
                onReady msg
        catch ex
            return


module.exports = DBConfig

class DBConfigConnection

    @getConnection: (service) ->
        addresses = EndpointService.getInstance().getComponentAddresses service
        try
            serverConfigAddress = addresses[Const.ENDPOINT_TYPE.DB_CONFIG][Const.SOCKET_TYPE.PUSH_PULL][0]
            dbConfigQueryAddress = addresses[Const.ENDPOINT_TYPE.DB_CONFIG_QUERY][Const.SOCKET_TYPE.REQ_REP][0]
            return new DBConfigConnection(serverConfigAddress, dbConfigQueryAddress)
        catch ex
            log.error "Couldn't find addresses for db config: #{service}!"
        return null

    _pushPullSocket: null
    _reqRepSocket: null

    constructor: (@serverConfigAddress, @dbConfigQueryAddress) ->

    sendServerConfig: (provider, tableMeta) =>

        @_pushPullSocket = zmq.socket(Const.ZMQ_PUSH)
        @_pushPullSocket.connect(@serverConfigAddress)

        tableMeta.Schema ?= ""
        serverConfigMessage =
            Type: Const.SERVER_CONFIG_TYPE
            Name: provider
            Tables: [tableMeta]
        @_pushPullSocket.send dbConfigProto.serialize serverConfigMessage, "virtdb.interface.pb.ServerConfig"

    getTables: (provider, onReady) =>
        dbConfigQueryMessage = Name: provider
        @_reqRepSocket = zmq.socket(Const.ZMQ_REQ)
        @_reqRepSocket.connect(@dbConfigQueryAddress)
        @_reqRepSocket.on "message", (msg) =>
            onReady dbConfigProto.parse msg, "virtdb.interface.pb.DbConfigReply"
        @_reqRepSocket.send dbConfigProto.serialize dbConfigQueryMessage, "virtdb.interface.pb.DbConfigQuery"

