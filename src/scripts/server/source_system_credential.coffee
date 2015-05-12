(require "source-map-support").install()
SourceSystemCredentialConnection = require './source_system_credential_connection'
log = (require "virtdb-connector").log
V_ = log.Variable
ReportError = require "./report-error"

class SourceSystemCredential

    constructor: () ->

    setCredential: (sourceSystemName, sourceSystemToken, credentialValues, callback) =>
        request =
            Type: "SET_CREDENTIAL"
            SetCred:
                SourceSysName: sourceSystemName
                SourceSysToken: sourceSystemToken
                Creds: credentialValues
        connection = new SourceSystemCredentialConnection
        connection.send request, (reply) =>
            if not (ReportError reply, callback)
                callback null, null

    getCredential: (sourceSystemName, sourceSystemToken, callback) =>
        request =
            Type: "GET_CREDENTIAL"
            GetCred:
                SourceSysName: sourceSystemName
                SourceSysToken: sourceSystemToken
        connection = new SourceSystemCredentialConnection
        connection.send request, (reply) =>
            if not (ReportError reply, callback)
                callback null, reply.GetCred.Creds

    deleteCredential: (sourceSystemName, sourceSystemToken, callback) =>
        request =
            Type: "DELETE_CREDENTIAL"
            DelCred:
                SourceSysName: sourceSystemName
                SourceSysToken: sourceSystemToken
        connection = new SourceSystemCredentialConnection
        connection.send request, (reply) =>
            if not (ReportError reply, callback)
                callback null, null

    setTemplate: (sourceSystemName, templates, callback) =>
        request =
            Type: "SET_TEMPLATE"
            SetTmpl:
                SourceSysName: sourceSystemName
                Templates: templates
        connection = new SourceSystemCredentialConnection
        connection.send request, (reply) =>
            if not (ReportError reply, callback)
                callback null, null

    getTemplate: (sourceSystemName, callback) =>
        request =
            Type: "GET_TEMPLATE"
            GetTmpl:
                SourceSysName: sourceSystemName
        connection = new SourceSystemCredentialConnection
        connection.send request, (reply) =>
            if not (ReportError reply, callback)
                callback null, reply.GetTmpl.Templates

module.exports = SourceSystemCredential