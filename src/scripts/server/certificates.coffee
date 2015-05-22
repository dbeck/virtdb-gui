router = require './router'
auth = require './authentication'
Config = require "./config"
timeout = require "connect-timeout"
Proto = require "virtdb-proto"
Connector = require 'virtdb-connector'
Const = Connector.Const

certStoreMessage = (request) ->
    try
        console.log 'Request to be sent to CERT_STORE', request
        type = 'virtdb.interface.pb.CertStoreRequest'
        return Proto.security.serialize request, type
    catch ex
        console.error ex

parseReply = (callback) ->
    return (err, reply) ->
        try
            console.log err, reply
            if not err? and reply?
                type = 'virtdb.interface.pb.CertStoreReply'
                console.log "Parsing proto"
                reply = Proto.security.parse reply, type
                console.log "PRoto parsed"
                if reply.Type is 'ERROR_MSG'
                    err = new Error reply.Err.Msg
        catch ex
            console.log "Exception: ", ex
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

        Connector.sendRequest Const.SECURITY_SERVICE, "CERT_STORE", request, parseReply (err, reply) ->
            reply = reply.List.Certs
            cb err, reply

    approveTempKey: (component, authCode, loginToken, cb) ->
        request = certStoreMessage
            Type: 'APPROVE_TEMP_KEY'
            Approve:
                AuthCode: authCode
                LoginToken: loginToken
                ComponentName: component

        Connector.sendRequest Const.SECURITY_SERVICE, "CERT_STORE", request, parseReply cb

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
        Connector.sendRequest Const.SECURITY_SERVICE, 'CERT_STORE', request, parseReply cb

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
            console.log err
            res.status(500).send()
            return
        res.json ""

router.delete "/certificate/:component"
    , auth.ensureAuthenticated
    , timeout(Config.getCommandLineParameter("timeout"))
, (req, res, next) ->
    CertificateClient.deleteKey req.params.component, req.body.publicKey, req.user.token, (err, results) ->
        if err?
            console.log err
            res.status(500).send()
            return
        res.json ""

module.exports = CertificateClient
