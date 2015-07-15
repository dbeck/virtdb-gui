VirtDBConnector = require "virtdb-connector"
TokenManager = VirtDBConnector.TokenManager
SourceSystemCredential = VirtDBConnector.SourceSystemCredential

getCredential = (token, sourceSystem, callback) ->
    TokenManager.getSourceSystemToken token, sourceSystem, (err, sourceSystemToken) ->
        if err?
            callback err, null
            return
        SourceSystemCredential.getCredential sourceSystem, sourceSystemToken, (err, credential) ->
            if err?
                callback err, null
                return
            callback null, credential
        return

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
    getSourceSystemToken: getSourceSystemToken