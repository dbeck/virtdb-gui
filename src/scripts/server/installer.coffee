config = require './config'
certStore = require './certificates'
VirtDB = require 'virtdb-connector'
user = require './user_manager'
token = require './token_manager'

getOwnCert = ->
    return {
        ComponentName: VirtDB.componentName
        PublicKey: VirtDB.publicKey
        Approved: false
    }

findOwnCert = (callback) ->
    try
        own = getOwnCert()
        certStore.listKeys (err, certs) ->
            console.log "ListKeys succeeded"
            if not err?
                for cert in certs when cert.ComponentName is own.ComponentName and cert.PublicKey is own.PublicKey
                    callback null, cert
                    return
            err ?= new Error("Own certificate not found")
            callback err, null
    catch ex
        callback ex, null

createAdmin = (token, username, password, callback) ->
    if username is 'admin'
        user.updateUser username, password, true, token, callback
    else
        user.createUser username, password, true, token, (err) ->
            if not err?
                user.deleteUser 'admin', token, callback

findOwnCert = (callback) ->
    callback null,
        ComponentName: 'virtdb-gui'
        AuthCode: '123'

Installer =
    process: (options, callback) ->
        console.dir options
        findOwnCert (err, cert) ->
            if err?
                console.log err
                callback err, null
                return
            component = cert.ComponentName
            authCode = cert.AuthCode
            loginToken = options.token
            certStore.approveTempKey component, authCode, loginToken, (err) ->
                console.log "Tempkey approved"
                if not err?
                    createAdmin options.token, options.username, options.password, (err) ->
                        if not err?
                            token.deleteToken options.token, options.token, (err) ->
                                if not err?
                                    config.Installed = true
                                callback err
                        else
                            callback err
                else
                    callback err

module.exports = Installer
