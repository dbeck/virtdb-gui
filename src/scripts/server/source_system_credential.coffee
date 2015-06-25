ReportError = require "./report-error"
SecurityProto = (require "virtdb-proto").security
VirtDB = require "virtdb-connector"
Const = VirtDB.Const
log = VirtDB.log
V_ = log.Variable

class SourceSystemCredential

    constructor: () ->

    setCredential: (sourceSystemName, sourceSystemToken, credentialValues, callback) =>
        request =
            Type: "SET_CREDENTIAL"
            SetCred:
                SourceSysName: sourceSystemName
                SourceSysToken: sourceSystemToken
                Creds: credentialValues
        sendRequest request, (err, reply) =>
            callback err, null

    getCredential: (sourceSystemName, sourceSystemToken, callback) =>
        request =
            Type: "GET_CREDENTIAL"
            GetCred:
                SourceSysName: sourceSystemName
                SourceSysToken: sourceSystemToken
        sendRequest request, (err, reply) =>
            if err?
                callback err, null
            else
                callback null, reply.GetCred.Creds

    deleteCredential: (sourceSystemName, sourceSystemToken, callback) =>
        request =
            Type: "DELETE_CREDENTIAL"
            DelCred:
                SourceSysName: sourceSystemName
                SourceSysToken: sourceSystemToken
        sendRequest request, (err, reply) =>
            callback err, null

    setTemplate: (sourceSystemName, templates, callback) =>
        request =
            Type: "SET_TEMPLATE"
            SetTmpl:
                SourceSysName: sourceSystemName
                Templates: templates
        sendRequest request, (err, reply) =>
            callback err, null

    getTemplate: (sourceSystemName, callback) =>
        request =
            Type: "GET_TEMPLATE"
            GetTmpl:
                SourceSysName: sourceSystemName
        sendRequest request, (err, reply) =>
            if err?
                callback err, null
            else
                callback null, reply.GetTmpl.Templates

    sendRequest = (request, cb) ->
        message = SecurityProto.serialize request, "virtdb.interface.pb.SourceSystemCredentialRequest"
        VirtDB.sendRequest Const.SECURITY_SERVICE, Const.ENDPOINT_TYPE.SRCSYS_CRED_MGR, message, (parseReply cb)
        VirtDB.MonitoringService.bumpStatistic "Source system credential request sent"

    parseReply = (callback) ->
        return (err, reply) ->
            try
                if not err? and reply?
                    try
                        reply = SecurityProto.parse reply, 'virtdb.interface.pb.SourceSystemCredentialReply'
                    catch ex
                        VirtDB.MonitoringService.requestError Const.SECURITY_SERVICE, Const.REQUEST_ERROR.INVALID_REQUEST, ex.toString()
                        throw ex
                    if reply.Type is 'ERROR_MSG'
                        err = new Error reply.Err.Msg
            catch ex
                err ?= ex
            finally
                callback? err, reply

module.exports = SourceSystemCredential