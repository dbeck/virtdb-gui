zmq = require "zmq"
fs = require "fs"
protobuf = require "node-protobuf"
log = require "loglevel"
NodeCache = require "node-cache"
ms = require "ms"
util = require "util"

Config = require "./config"
Const = (require "virtdb-connector").Constants
FieldData = require "./fieldData"
EndpointService = require "./endpoint_service"

require("source-map-support").install()
log.setLevel "debug"

dbConfigProto = new protobuf(fs.readFileSync("common/proto/db_config.pb.desc"))

CACHE_TTL = ms(Config.Values.CACHE_TTL)/1000
CACHE_CHECK_PERIOD = ms(Config.Values.CACHE_CHECK_PERIOD)/1000

class DBConfig

    @_configuredTablesCache = new NodeCache({ stdTTL: CACHE_TTL, checkperiod: CACHE_CHECK_PERIOD})
    @_configuredTablesCache.on "expired", (key, value) =>
        log.debug "DB config cache expired:", key

    @addTable: (provider, tableMeta) =>
        if not tableMeta?
            log.error "Couldn't add table to the db config due to a problem with the meta data:", tableMeta
            return

        connection = DBConfigConnection.getConnection(Config.Values.DB_CONFIG_SERVICE)
        try
            connection.sendServerConfig provider, tableMeta
            log.debug "Table added to the db config:", tableMeta.Name, provider
            @_configuredTablesCache.del(provider)
        catch ex
            return

    @getTables: (provider, onReady) =>
        try
            tableList = @_configuredTablesCache.get(provider)[provider]
            if tableList? and util.isArray tableList
                log.debug "Serving list of already added tables from cache.", provider
                onReady tableList
            else
                log.debug "Serving list of already added tables from db config.", provider
                connection = DBConfigConnection.getConnection(Config.Values.DB_CONFIG_SERVICE)
                connection.getTables provider, (msg) =>
                        if msg?.Servers[0]?.Tables?
                            tableList = []
                            for table in msg.Servers[0].Tables
                                tableList.push table.Schema + "." + table.Name
                            if tableList.length > 0
                                @_configuredTablesCache.set(provider, tableList)
                            onReady tableList
        catch ex
            log.error "Couldn't fill cache.", provider, ex
            onReady []
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

