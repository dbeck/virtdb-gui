zmq = require "zmq"
util = require "util"
Cache = require "./cache_handler"

VirtDB = require "virtdb-connector"
Config = require "./config"
Const = VirtDB.Const
log = VirtDB.log
V_ = log.Variable
Protocol = require "./protocol"
User = require './user'

class DBConfig

    dbConfig = null
    DB_CONFIG_CACHE_PREFIX = "db_config_tables"

    @setDBConfig: (name) ->
        dbConfig = name
        emptyDBConfigCache()

    @getTables: (provider, username, onReady) ->
        try
            if (replyFromCache provider, onReady)
                return

            if not dbConfig?
                log.error "missing db config service"
                onReady []
                return

            message =
                Type: 'QUERY_TABLES'
                QueryTables:
                    Provider: provider

            if Config.Features.Security and username?
                message.QueryTables.UserName = username

            Protocol.sendDBConfig dbConfig, message, (err, msg) ->
                try
                    if err?
                        throw err
                    if msg?.QueryTables?.Tables?.length > 0
                        makeTableListResponse provider, msg.QueryTables.Tables, onReady
                    else
                        onReady []
                catch ex
                    log.error V_(ex)
                    throw ex
            return
        catch ex
            log.error V_(ex)
            throw ex

    @addUserMapping: (provider, username, token, callback) ->
        if not (checkDBConfig callback)?
            return

        message =
            Type: 'ASSIGN_USER'
            AssignUser:
                Provider: provider
                UserName: username
                Token: token

        Protocol.sendDBConfig dbConfig, message, (err, reply) ->
            callback (handleError err, reply, "Error while adding user mapping"), null

    @createUser: (username, password, callback) ->
        if not (checkDBConfig callback)?
            return

        message =
            Type: 'CREATE_USER'
            CreateUser:
                UserName: username
        if password?
            message["CreateUser"]["Password"] = password

        Protocol.sendDBConfig dbConfig, message, (err, reply) ->
            callback (handleError err, reply, "Error while creating user"), null

    @updateUser: (username, password, callback) ->
        if not (checkDBConfig callback)?
            return

        message =
            Type: 'UPDATE_USER'
            UpdateUser:
                UserName: username
                Password: password

        Protocol.sendDBConfig dbConfig, message, (err, reply) ->
            callback (handleError err, reply, "Error while updating user"), null

    @deleteUser: (username, callback) ->
        if not (checkDBConfig callback)?
            return

        message =
            Type: 'DELETE_USER'
            DeleteUser:
                UserName: username

        Protocol.sendDBConfig dbConfig, message, (err, reply) ->
            callback (handleError err, reply, "Error while deleting user"), null

    @listUsers: (callback) ->
        if not (checkDBConfig callback)?
            return

        message =
            Type: 'LIST_USERS'

        Protocol.sendDBConfig dbConfig, message, (err, reply) ->
            error = handleError err, reply, "Error while getting DB users"
            if error?
                callback error, null
                return
            if reply?.Users?.Name?
                callback null, reply.Users.Name

    @deleteTable: (provider, tableMeta, username, callback) ->
        if (not (checkDBConfig callback)?) or (not (checkMetadata tableMeta))
            return

        message =
            Type: 'DELETE_TABLE'
            DeleteTable:
                Provider: provider
                Table: tableMeta.Tables[0]

        if Config.Features.Security and username?
            message.AddTable?.UserName = username

        Protocol.sendDBConfig dbConfig, message, (err, reply) ->
            error = handleError err, reply, "Error deleting table to db config"
            if error?
                log.info "table deleted from the db config", V_(tableMeta.Tables[0].Name), V_(provider)
            else
                log.error "table could not be deleted from db config", V_(error), V_(tableMeta.Tables[0].Name), V_(provider)
            Cache.delete cacheKey provider
            log.debug "db config cache were emptied", V_(tableMeta.Tables[0].Name), V_(provider)
            callback error

    @addTable: (provider, tableMeta, username, callback) ->
        if (not (checkDBConfig callback)?) or (not (checkMetadata tableMeta))
            return

        message =
            Type: 'ADD_TABLE'
            AddTable:
                Provider: provider
                Table: tableMeta.Tables[0]

        if Config.Features.Security and username?
            message.AddTable?.UserName = username

        Protocol.sendDBConfig dbConfig, message, (err, reply) ->
            error = handleError err, reply, "Error adding table to db config"
            if error?
                log.error "table could not be added to db config", V_(error), V_(tableMeta.Tables[0].Name), V_(provider)
            else
                log.info "table added to the db config", V_(tableMeta.Tables[0].Name), V_(provider)
            Cache.delete cacheKey provider
            log.debug "db config cache were emptied", V_(tableMeta.Tables[0].Name), V_(provider)
            callback error

    emptyDBConfigCache = () =>
        keys = Cache.listKeys()
        for key in keys
            if key.indexOf(DB_CONFIG_CACHE_PREFIX) is 0
                Cache.delete key

    checkMetadata = (metadata) ->
        if not metadata?
            log.error "couldn't add table to the db config due to a problem with the meta data", V_(metadata)
            return false

        if metadata.Tables.length is not 1
            log.error "exactly one table should be in metadata", V_(metadata)
        return true

    makeTableListResponse = (provider, tables, callback) ->
        tableList = []
        for table in tables
            if not table.Schema? or table.Schema is ""
                tableList.push table.Name
            else
                tableList.push table.Schema + "." + table.Name
        if tableList.length > 0
            Cache.set (cacheKey provider), tableList
        callback tableList

    replyFromCache = (provider, onReady) ->
        tableList = Cache.get cacheKey provider
        if tableList? and util.isArray tableList
            log.trace "getting list of already added tables from cache.", V_(provider)
            onReady tableList
            return true
        return false

    cacheKey = (provider) ->
        return DB_CONFIG_CACHE_PREFIX + "_" + provider

    handleError = (err, reply, desc) ->
        error = null
        if err?
            error = err
        if reply?.Err?
            error = new Error reply.Err.Msg
        if error?
            log.error desc, V_(error)
        return error

    checkDBConfig = (callback) ->
        text = "DBConfig service is not set"
        if not dbConfig?
            log.error text
            callback? (new Error text), null
        return dbConfig

Config.addConfigListener Config.DB_CONFIG_SERVICE, DBConfig.setDBConfig
module.exports = DBConfig
