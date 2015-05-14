VirtDB = require 'virtdb-connector'
Const = VirtDB.Const
log = VirtDB.log
V_ = log.Variable
sendSecurityMessage = (require './protocol').sendSecurityMessage

class TokenManager
    @createLoginToken: (user, pass, callback) ->
        rawRequest =
            Type: "CREATE_LOGIN_TOKEN"
            CrLoginTok:
                UserName: user
                Password: pass

        sendSecurityMessage Const.ENDPOINT_TYPE.USER_MGR, rawRequest, (err, message) ->
            data = null
            if not err? and message?.CrLoginTok?.LoginToken?
                data = message.CrLoginTok.LoginToken
            else
                err ?= new Error "Message does not contain a CrLoginTok.LoginToken member"
            callback err, data

    @createSourceSystemToken: (token, sourceSystemName, callback) ->
        request =
            Type: "CREATE_SOURCESYS_TOKEN"
            CrSSTok:
                LoginToken: token
                SourceSysName: sourceSystemName

        sendSecurityMessage Const.ENDPOINT_TYPE.USER_MGR, request, (err, message) ->
            data = null
            if not err? and message?.CrSSTok?.SourceSysToken?
                data = message.CrSSTok.SourceSysToken
            else
                err ?= new Error "Message does not contain a CrSSTok.SourceSysToken member"
            callback err, data

    @getSourceSystemToken: (token, sourceSystemName, callback) ->
        request =
            Type: "GET_SOURCESYS_TOKEN"
            GetSSTok:
                LoginOrTableToken: token
                SourceSysName: sourceSystemName

        sendSecurityMessage Const.ENDPOINT_TYPE.USER_MGR, request, (err, message) ->
            data = null
            if not err? and message?.GetSSTok?.SourceSysToken?
                data = message.GetSSTok.SourceSysToken
            else
                err ?= new Error "Message does not contain a CrSSTok.SourceSysToken member"
            callback err, data

    @createTableToken: (token, sourceSystemName, callback) ->
        request =
            Type: "CREATE_TABLE_TOKEN"
            CrTabTok:
                LoginToken: token
                SourceSysName: sourceSystemName

        sendSecurityMessage Const.ENDPOINT_TYPE.USER_MGR, request, (err, message) ->
            data = null
            if not err? and message?.CrTabTok.TableToken?
                data = message.CrTabTok.TableToken
            else
                err ?= new Error "Message does not contain a CrSSTok.SourceSysToken member"
            callback err, data

    @deleteToken: (loginToken, anyToken, callback) ->
        request =
            Type: "DELETE_TOKEN"
            DelTok:
                LoginToken: loginToken
                AnyTokenValue: anyToken

        sendSecurityMessage Const.ENDPOINT_TYPE.USER_MGR, request, (err, message) ->
            callback err, null

module.exports = TokenManager
