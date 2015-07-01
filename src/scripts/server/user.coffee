TokenManager = require './token_manager'

class User
    tableTokens: null
    token: null
    constructor: (@name, @password) ->
        @tableTokens = {}
    authenticate: (done) =>
        TokenManager.createLoginToken @name, @password, (err, user) =>
            if err?
                done? null, false, {message: err.toString()}
                return
            @password = null
            @token = user.LoginToken
            @tableTokens = {}
            @isAdmin = user.Data.IsAdmin
            done? null, @
            return

    getTableToken: (sourceSystem, done) =>
        if @tableTokens[sourceSystem]?
            done null, @tableTokens[sourceSystem]
            return
        TokenManager.createTableToken @token, sourceSystem, (err, tableToken) =>
            if err?
                done err, null
                return
            @tableTokens[sourceSystem] = tableToken
            done null, tableToken


module.exports = User
