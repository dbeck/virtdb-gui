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
        log.debug "Adding table: #{tableMeta.Name} of provider: #{provider} to the db config"
        connection = DBConfigConnection.getConnection(Config.Values.DB_CONFIG_SERVICE)
        try
            connection.sendServerConfig provider, tableMeta
        catch ex
            return


module.exports = DBConfig

class DBConfigConnection

    @getConnection: (service) ->
        addresses = EndpointService.getInstance().getComponentAddress service
        try
            dbConfigAddress = addresses[Const.ENDPOINT_TYPE.DB_CONFIG][Const.SOCKET_TYPE.PUSH_PULL][0]
            return new DBConfigConnection(dbConfigAddress)
        catch ex
            log.error "Couldn't find addresses for db config: #{service}!"
        return null

    _pushPullSocket: null

    constructor: (@dbConfigAddress) ->

    sendServerConfig: (provider, tableMeta) =>

        @_pushPullSocket = zmq.socket(Const.ZMQ_PUSH)
        @_pushPullSocket.connect(@dbConfigAddress)

        tableMeta.Schema ?= ""
        serverConfigMessage =
            Type: Const.SERVER_CONFIG_TYPE
            Name: provider
            Tables: [tableMeta]
        @_pushPullSocket.send dbConfigProto.serialize serverConfigMessage, "virtdb.interface.pb.ServerConfig"
