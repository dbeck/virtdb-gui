config = require './config'
certStore = require './certificates'
VirtDB = require 'virtdb-connector'
user = require './user_manager'
token = require './token_manager'
fs = require 'fs'

getOwnCert = ->
    return {
        ComponentName: VirtDB.Const.COMPONENT_NAME
        PublicKey: VirtDB.publicKey
        Approved: false
    }

findOwnCert = (callback) ->
    try
        own = getOwnCert()
        certStore.listKeys (err, certs) ->
            if err?
                console.error "listKeys err: ", err
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

setInstalled =  ->
    config.Installed = true
    fs.readFile 'curve.json', (err, data) ->
        curve = JSON.parse data
        if not err?
            curve.Installed = true
            data = JSON.stringify curve, null, 4
            fs.writeFile 'curve.json', data, (err) ->
                if err?
                    console.error "Error storing installed state.", err
        else
            console.error err

checkInstalled = (callback) ->
    if not config.Features.Installer
        callback()
        return

    fs.readFile 'curve.json', (err, data) ->
        if not err?
            curve = JSON.parse data
            config.Installed = curve?.Installed? and curve.Installed
        callback()

Installer =
    checkStatus: checkInstalled
    process: (options, callback) ->
        findOwnCert (err, cert) ->
            if err?
                console.error "Find own cert err: ", err
                callback err, null
                return
            component = VirtDB.Const.COMPONENT_NAME
            authCode = VirtDB.authCode
            loginToken = options.token
            certStore.approveTempKey component, authCode, loginToken, (err) ->
                if not err?
                    createAdmin options.token, options.username, options.password, (err) ->
                        if not err?
                            token.deleteToken options.token, options.token, (err) ->
                                setInstalled()
                                callback err
                        else
                            callback err
                else
                    console.error "approveTempKey err:", err
                    callback err

module.exports = Installer
