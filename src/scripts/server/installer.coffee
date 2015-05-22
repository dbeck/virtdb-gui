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

Installer =
    process: (options, callback) ->
        findOwnCert (err, cert) ->
            if err?
                callback err, null
                return
            component = VirtDB.componentName
            authCode = VirtDB.authCode
            loginToken = options.token
            certStore.approveTempKey component, authCode, loginToken, (err) ->
                if not err?
                    createAdmin options.token, options.username, options.password, (err) ->
                        if not err?
                            token.deleteToken options.token, options.token, (err) ->
                                config.Installed = true
                                callback err
                        else
                            callback err
                else
                    callback err

module.exports = Installer
