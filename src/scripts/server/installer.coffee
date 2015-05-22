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
        console.log "FindownCert begins"
        own = getOwnCert()
        console.log "Calling listkeys"
        certStore.listKeys (err, certs) ->
            console.log "ListKeys succeeded", err, certs
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
            console.log "Create user response: ", err
            if not err?
                console.log "Deleting user"
                user.deleteUser 'admin', token, callback

Installer =
    process: (options, callback) ->
        console.dir options
        findOwnCert (err, cert) ->
            if err?
                console.log err
                callback err, null
                return
            component = VirtDB.componentName
            authCode = VirtDB.authCode
            loginToken = options.token
            console.log "Approving temp key", component, loginToken, authCode
            certStore.approveTempKey component, authCode, loginToken, (err) ->
                console.log "Tempkey approved"
                if not err?
                    console.log "Creating admin user"
                    createAdmin options.token, options.username, options.password, (err) ->
                        console.log "Created admin user: ", err
                        if not err?
                            console.log "Deleting token: ", options.token
                            token.deleteToken options.token, options.token, (err) ->
                                console.log "DeletToken finished.", err
                                config.Installed = true
                                callback err
                        else
                            callback err
                else
                    callback err

module.exports = Installer
