VirtDBConnector = require "virtdb-connector"
TokenManager = VirtDBConnector.TokenManager
SourceSystemCredential = VirtDBConnector.SourceSystemCredential
log = VirtDBConnector.log
V_ = log.Variable

getCredential = (token, sourceSystem, callback) ->
    VirtDBConnector.SourceSystemCredential.getTemplate sourceSystem, (err, template) ->
        if err?
            log.error "Error during getting credential template", (V_ sourceSystem), (V_ err)
            callback err, null
            return
        TokenManager.getSourceSystemToken token, sourceSystem, (err, sourceSystemToken) ->
            if err?
                log.warn "Error during getting source system token", (V_ sourceSystem), (V_ err)
                callback null, template
                return
            SourceSystemCredential.getCredential sourceSystem, sourceSystemToken, (err, credential) ->
                if err?
                    log.warn "Error during getting credentials", (V_ sourceSystem), (V_ err)
                    callback null, template
                    return
                mergeTemplateCredential template, credential, callback
            return

mergeTemplateCredential = (template, credential, callback) ->
    result = []
    for field in credential.NamedValues
        element = {}
        for templateField in template
            if templateField.Name is field.Name
                element["Type"] ?= templateField.Type
                element["Name"] ?= field.Name
                element["Value"] ?= field.Value
        result.push element
    callback null, result

setCredential = (token, sourceSystem, credential, callback) ->
    getSourceSystemToken token, sourceSystem, (err, sourceSystemToken) ->
        if err?
            callback err
            return
        credentials =
            NamedValues: credential
        VirtDBConnector.SourceSystemCredential.setCredential sourceSystem, sourceSystemToken, credentials, (err, result) ->
            callback err

getSourceSystemToken = (token, sourceSystem, callback) ->
    TokenManager.getSourceSystemToken token, sourceSystem, (err, sourceSystemToken) ->
        if sourceSystemToken?
            callback null, sourceSystemToken
            return
        TokenManager.createSourceSystemToken token, sourceSystem, (err, sourceSystemToken) ->
            if err?
                callback err, null
                return
            callback null, sourceSystemToken
            return

module.exports =
    getCredential: getCredential
    setCredential: setCredential
