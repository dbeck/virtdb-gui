zmq = require "zmq"
util = require "util"
Cache = require "./cache_handler"

Config = require "./config"
VirtDB = require "virtdb-connector"
Const = VirtDB.Const
log = VirtDB.log
V_ = log.Variable
Protocol = require "./protocol"
User = require './user'

class DBConfig

    dbConfig = null

    @setDBConfig: (name) ->
        dbConfig = name
        Cache.emptyDBConfig()

    @getTables: (provider, username, onReady) ->
        try
            if (replyFromCache provider, onReady)
                return

            err = checkDBConfig()
            if err?
                onReady []
                log.error V_ err
                return

            message =
                Type: 'QUERY_TABLES'
                QueryTables:
                    Provider: provider

            if Config.Features.Security and username?
                message.QueryTables.UserName = username

            Protocol.sendDBConfig dbConfig, message, (err, msg) ->
                error = collectError err, msg, "Error while listing added tables for: #{provider}"
                if not error and msg?.QueryTables?.Tables?.length > 0
                    makeTableListResponse provider, msg.QueryTables.Tables, onReady
                else
                    onReady []
                    return
            return
        catch ex
            log.error V_(ex)
            throw ex

    @addUserMapping: (provider, username, token, callback) ->
        err = checkDBConfig()
        if err?
            callback? err, null
            log.error V_ err
            return

        message =
            Type: 'ASSIGN_USER'
            AssignUser:
                Provider: provider
                UserName: username
                Token: token

        Protocol.sendDBConfig dbConfig, message, (err, reply) ->
            callback? (collectError err, reply, "Error while adding user mapping"), null

    @createUser: (username, password, callback) ->
        err = checkDBConfig()
        if err?
            callback? err, null
            log.error V_ err
            return

        message =
            Type: 'CREATE_USER'
            CreateUser:
                UserName: username
        if password?
            message["CreateUser"]["Password"] = password

        Protocol.sendDBConfig dbConfig, message, (err, reply) ->
            callback? (collectError err, reply, "Error while creating user"), null

    @updateUser: (username, password, callback) ->
        err = checkDBConfig()
        if err?
            callback? err, null
            log.error V_ err
            return

        message =
            Type: 'UPDATE_USER'
            UpdateUser:
                UserName: username
                Password: password

        Protocol.sendDBConfig dbConfig, message, (err, reply) ->
            callback? (collectError err, reply, "Error while updating user"), null

    @deleteUser: (username, callback) ->
        err = checkDBConfig()
        if err?
            callback? err, null
            log.error V_ err
            return

        message =
            Type: 'DELETE_USER'
            DeleteUser:
                UserName: username

        Protocol.sendDBConfig dbConfig, message, (err, reply) ->
            callback? (collectError err, reply, "Error while deleting user"), null

    @listUsers: (callback) ->
        err = checkDBConfig()
        if err?
            callback err, null
            log.error V_ err
            return

        message =
            Type: 'LIST_USERS'

        Protocol.sendDBConfig dbConfig, message, (err, reply) ->
            error = collectError err, reply, "Error while getting DB users"
            if error?
                callback error, null
                return
            if reply?.Users?.Name?
                callback null, reply.Users.Name

    @deleteTable: (provider, tableMeta, username, callback) ->
        err = checkDBConfig()
        if err?
            callback? err
            log.error V_ err
            return

        err = checkMetadata(tableMeta)
        if err?
            callback? err
            log.error V_ err
            return

        message =
            Type: 'DELETE_TABLE'
            DeleteTable:
                Provider: provider
                Table: tableMeta.Tables[0]

        if Config.Features.Security and username?
            message.DeleteTable?.UserName = username

        Protocol.sendDBConfig dbConfig, message, (err, reply) ->
            error = collectError err, reply, "Error deleting table from db config: #{provider}/#{tableMeta.Tables[0].Name}"
            if not error?
                log.info "table deleted from the db config", V_(tableMeta.Tables[0].Name), V_(provider)
            Cache.delete Cache.generateDBConfigCacheKey provider
            log.debug "db config cache were emptied", V_(tableMeta.Tables[0].Name), V_(provider)
            callback? error

    @addTable: (provider, tableMeta, username, callback) ->
        err = checkDBConfig()
        if err?
            callback? err
            log.error V_ err
            return

        err = checkMetadata(tableMeta)
        if err?
            callback? err
            log.error V_ err
            return

        message =
            Type: 'ADD_TABLE'
            AddTable:
                Provider: provider
                Table: tableMeta.Tables[0]

        if Config.Features.Security and username?
            message.AddTable?.UserName = username

        Protocol.sendDBConfig dbConfig, message, (err, reply) ->
            error = collectError err, reply, "Error adding table to db config: #{provider}/#{tableMeta.Tables[0].Name}"
            if not error?
                log.info "table added to the db config", V_(tableMeta.Tables[0].Name), V_(provider)
            Cache.delete Cache.generateDBConfigCacheKey provider
            log.debug "db config cache were emptied", V_(tableMeta.Tables[0].Name), V_(provider)
            callback? error

    checkMetadata = (metadata) ->
        if not metadata?
            return new Error "couldn't add table to the db config due to a problem with the meta data: #{metadata}"
        if metadata.Tables.length is not 1
            return new Error "exactly one table should be in metadata: #{metadata}"
        return null

    makeTableListResponse = (provider, tables, callback) ->
        tableList = []
        for table in tables
            if not table.Schema? or table.Schema is ""
                tableList.push
                    name: table.Name
                    materialized: table.Properties[0].Value.BoolValue[0]
            else
                tableList.push
                    name: table.Schema + "." + table.Name
                    materialized: table.Properties[0].Value.BoolValue[0]
        if tableList.length > 0
            Cache.set (Cache.generateDBConfigCacheKey provider), tableList
        callback tableList

    replyFromCache = (provider, onReady) ->
        tableList = Cache.get Cache.generateDBConfigCacheKey provider
        if tableList? and util.isArray tableList
            log.trace "getting list of already added tables from cache.", V_(provider)
            onReady tableList
            return true
        return false

    collectError = (err, reply, desc) ->
        error = null
        if err?
            error = err
        if reply?.Err?
            error = new Error reply.Err.Msg
        if error?
            log.error desc, V_(error)
        return error

    checkDBConfig =  ->
        if not dbConfig?
            return new Error "DBConfig service is not set"
        return null

Config.addConfigListener Config.DB_CONFIG_SERVICE, DBConfig.setDBConfig
module.exports = DBConfig
