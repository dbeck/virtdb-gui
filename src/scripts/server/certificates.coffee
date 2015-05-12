router = require './router'
auth = require './authentication'
Config = require "./config"
timeout = require "connect-timeout"
Proto = require "virtdb-proto"
Connector = require 'virtdb-connector'

certStoreMessage = (request) ->
    try
        console.log "Serializing request", request
        type = "virtdb.interface.pb.CertStoreRequest"
        return Proto.security.serialize request, type
    catch ex
        console.error ex

listKeys = (cb) ->
    request = certStoreMessage
        Type: 'LIST_KEYS'
        List:
            TempKeys: true
            ApprovedKeys: true

    console.log "Getting component list", (Proto.security.parse request, "virtdb.interface.pb.CertStoreRequest")
    Connector.sendRequest 'security-dummy', "CERT_STORE", request, (err, reply) ->
        console.log "Cert store reply: ", err, reply
        if not err? and reply?
            reply = Proto.security.parse reply, "virtdb.interface.pb.CertStoreReply"
            switch reply.Type
                when 'ERROR_MSG'
                    err = new Error reply.Err.Msg
                when 'LIST_KEYS'
                    reply = reply.List.Certs
                    console.log "List reply: ", reply
                else
                    err = new Error "Bad reply type. Asked for LIST_KEYS. Got: #{reply.Type}"
        cb err, reply

approveTempKey = (component, authCode, loginToken, cb) ->
    request = certStoreMessage
        Type: 'APPROVE_TEMP_KEY'
        Approve:
            AuthCode: authCode
            LoginToken: loginToken

    Connector.send "CERT_STORE", request, cb

deleteKey = (component, loginToken, cb) ->
    request = certStoreMessage
        Type: 'DELETE_KEY'
        Del:
            Cert: component
            LoginToken: loginToken

    Connector.send 'CERT_STORE', request, cb

router.get "/certificate"
    , auth.ensureAuthenticated
    , timeout(Config.getCommandLineParameter("timeout"))
, (req, res, next) ->
    listKeys (err, results) ->
        if err?
            res.status(500).send()
            return
        res.json results

router.put "/certificate/:component"
    , auth.ensureAuthenticated
    , timeout(Config.getCommandLineParameter("timeout"))
, (req, res, next) ->
    console.log "Approve request arrived.", req.params.component
    console.log "AuthCode: ", req.body.authCode
    approveTempKey req.params.component, req.body.authCode, req.user.token, (err, results) ->
        res.json ""

router.delete "/certificate/:component"
    , auth.ensureAuthenticated
    , timeout(Config.getCommandLineParameter("timeout"))
, (req, res, next) ->
    deleteKey req.params.component, req.user.token, (err, results) ->
        res.json ""
