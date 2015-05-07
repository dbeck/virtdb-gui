(require "source-map-support").install()
UserManagerConnection = require './user_manager_connection'
log = (require "virtdb-connector").log
V_ = log.Variable
ReportError = require "./report-error"

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
            if not (ReportError reply, callback)
                callback null, reply.CrLoginTok.LoginToken

    createSourceSystemToken: (token, sourceSystemName, callback) =>
        request = 
            Type: "CREATE_SOURCESYS_TOKEN"
            CrSSTok:
                LoginToken: token
                SourceSysName: sourceSystemName
        connection = new UserManagerConnection
        connection.send request, (reply) =>
            if not (ReportError reply, callback)
                callback null, reply.CrSSTok.SourceSysToken

    getSourceSystemToken: (token, sourceSystemName, callback) =>
        request = 
            Type: "GET_SOURCESYS_TOKEN"
            GetSSTok:
                LoginOrTableToken: token
                SourceSysName: sourceSystemName
        connection = new UserManagerConnection
        connection.send request, (reply) =>
            if not (ReportError reply, callback)
                callback null, reply.GetSSTok.SourceSysToken

    createTableToken: (token, sourceSystemName, callback) =>
        request = 
            Type: "CREATE_TABLE_TOKEN"
            CrTabTok:
                LoginToken: token
                SourceSysName: sourceSystemName
        connection = new UserManagerConnection
        connection.send request, (reply) =>
            if not (ReportError reply, callback)
                callback null, reply.CrTabTok.TableToken

    deleteToken: (loginToken, anyToken, callback) =>
        request = 
            Type: "DELETE_TOKEN"
            DelTok:
                LoginToken: loginToken
                AnyTokenValue: anyToken
        connection = new UserManagerConnection
        connection.send request, (reply) =>
            if not (ReportError reply, callback)
                callback null, null

module.exports = TokenManager
