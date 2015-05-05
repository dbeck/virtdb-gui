(require "source-map-support").install()
UserManagerConnection = require './user_manager_connection'
log = (require "virtdb-connector").log
V_ = log.Variable

class TokenManager

    constructor: () ->

    createLoginToken: (user, pass, callback) =>
        request = 
            Type: "CREATE_LOGIN_TOKEN"
            CrLoginTok:
                UserName: user
                Password: pass
        connection = new UserManagerConnection
        connection.send request, (reply) =>
            if not (reportErrors reply, callback)
                callback null, reply.CrLoginTok.LoginToken

    createSourceSystemToken: (token, sourceSystemName, callback) =>
        request = 
            Type: "CREATE_SOURCESYS_TOKEN"
            CrSSTok:
                LoginToken: token
                SourceSysName: sourceSystemName
        connection = new UserManagerConnection
        connection.send request, (reply) =>
            if not (reportErrors reply, callback)
                callback null, reply.CrSSTok.SourceSysToken

    getSourceSystemToken: (token, sourceSystemName, callback) =>
        request = 
            Type: "GET_SOURCESYS_TOKEN"
            GetSSTok:
                LoginOrTableToken: token
                SourceSysName: sourceSystemName
        connection = new UserManagerConnection
        connection.send request, (reply) =>
            if not (reportErrors reply, callback)
                callback null, reply.GetSSTok.SourceSysToken

    createTableToken: (token, sourceSystemName, callback) =>
        request = 
            Type: "CREATE_TABLE_TOKEN"
            CrTabTok:
                LoginToken: token
                SourceSysName: sourceSystemName
        connection = new UserManagerConnection
        connection.send request, (reply) =>
            if not (reportErrors reply, callback)
                callback null, reply.CrTabTok.TableToken

    deleteToken: (loginToken, anyToken, callback) =>
        request = 
            Type: "DELETE_TOKEN"
            DelTok:
                LoginToken: loginToken
                AnyTokenValue: anyToken
        connection = new UserManagerConnection
        connection.send request, (reply) =>
            if not (reportErrors reply, callback)
                callback null, null

    reportErrors = (reply, callback) =>
        if not reply?
            err = new Error "Problem during communicating with the security service"
            callback err, null
            return true
        if reply.Type is "ERROR_MSG"
            err = new Error reply.Err.Msg
            log.error "Security service responded with error", V_(err)
            callback err, null
            return true
        return false


module.exports = TokenManager
