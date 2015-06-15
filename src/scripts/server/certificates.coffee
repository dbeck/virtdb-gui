router = require './router'
auth = require './authentication'
Config = require "./config"
timeout = require "connect-timeout"
Proto = require "virtdb-proto"
VirtDB = require 'virtdb-connector'
Const = VirtDB.Const

certStoreMessage = (request) ->
    try
        return Proto.security.serialize request, 'virtdb.interface.pb.CertStoreRequest'
    catch ex
        console.error ex

parseReply = (callback) ->
    return (err, reply) ->
        try
            if not err? and reply?
                type = 'virtdb.interface.pb.CertStoreReply'
                try
                    reply = Proto.security.parse reply, type
                catch ex
                    VirtDB.MonitoringService.requestError Const.SECURITY_SERVICE, Const.REQUEST_ERROR.INVALID_REQUEST, ex.toString()
                    throw ex
                if reply.Type is 'ERROR_MSG'
                    err = new Error reply.Err.Msg
        catch ex
            err ?= ex
        finally
            callback? err, reply

CertificateClient =
    listKeys: (cb) ->
        request = certStoreMessage
            Type: 'LIST_KEYS'
            List:
                TempKeys: true
                ApprovedKeys: true

        VirtDB.sendRequest Const.SECURITY_SERVICE, "CERT_STORE", request, parseReply (err, reply) ->
            reply = reply.List.Certs
            cb err, reply

    approveTempKey: (component, authCode, loginToken, cb) ->
        request = certStoreMessage
            Type: 'APPROVE_TEMP_KEY'
            Approve:
                AuthCode: authCode
                LoginToken: loginToken
                ComponentName: component

        VirtDB.sendRequest Const.SECURITY_SERVICE, "CERT_STORE", request, parseReply cb

    deleteKey: (componentName, publicKey, loginToken, cb) ->
        request = certStoreMessage
            Type: 'DELETE_KEY'
            Del:
                Cert:
                    ComponentName: componentName
                    PublicKey: publicKey
                    Approved: true
                LoginToken: loginToken
        type = "virtdb.interface.pb.CertStoreRequest"
        requestParsed = Proto.security.parse request, type
        VirtDB.sendRequest Const.SECURITY_SERVICE, 'CERT_STORE', request, parseReply cb

router.get "/certificate"
    , auth.ensureAuthenticated
    , timeout(Config.getCommandLineParameter("timeout"))
, (req, res, next) ->
    CertificateClient.listKeys (err, results) ->
        if err?
            res.status(500).send()
            return
        res.json results

router.put "/certificate/:component"
    , auth.ensureAuthenticated
    , timeout(Config.getCommandLineParameter("timeout"))
, (req, res, next) ->
    CertificateClient.approveTempKey req.params.component, req.body.authCode, req.user.token, (err, results) ->
        if err?
            res.status(500).send()
            return
        res.json ""

router.delete "/certificate/:component"
    , auth.ensureAuthenticated
    , timeout(Config.getCommandLineParameter("timeout"))
, (req, res, next) ->
    CertificateClient.deleteKey req.params.component, req.body.publicKey, req.user.token, (err, results) ->
        if err?
            res.status(500).send()
            return
        res.json ""

module.exports = CertificateClient
