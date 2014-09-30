CONST = require("./config").Const
zmq = require("zmq")
fs = require("fs")
protobuf = require("node-protobuf")
protoMetaData = new protobuf(fs.readFileSync("proto/meta_data.pb.desc"))
protoDBConfig = new protobuf(fs.readFileSync("proto/db_config.pb.desc"))
log = require("loglevel")
require('source-map-support').install()
FieldData = require './fieldData'
log.setLevel 'debug'
ServiceConfig = require('./svcconfig_connector')

class DBConfig

    @addTable: (provider, tableMeta) =>
        log.debug "Adding table: #{tableMeta.Name} of provider: #{provider} to the db config"
        connection = DBConfigConnection.getConnection(CONST.DB_CONFIG_SERVICE)
        connection.sendServerConfig provider, tableMeta
        return


module.exports = DBConfig

class DBConfigConnection

    @_configService = ServiceConfig.getInstance()

    @getConnection: (service) ->
        addresses = @_configService.getAddresses service
        try
            dbConfigAddress = addresses["DB_CONFIG"]["PUSH_PULL"][0]
        catch ex
            log.error "Couldn't get service addresses!"
            throw ex
        return new DBConfigConnection(dbConfigAddress)

    _pushPullSocket: null

    constructor: (@dbConfigAddress) ->

    sendServerConfig: (provider, tableMeta) =>

        @_pushPullSocket = zmq.socket('push')
        @_pushPullSocket.connect(@dbConfigAddress)

        tableMeta.Schema?= ""
        serverConfigMessage =
            Type: "42"
            Name: provider
            Tables: [tableMeta]
        @_pushPullSocket.send protoDBConfig.serialize serverConfigMessage, "virtdb.interface.pb.ServerConfig"
