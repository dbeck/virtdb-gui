TokenManager = (require "virtdb-connector").TokenManager

class User

    tableTokens: null
    sourceSystemTokens: null
    token: null

    constructor: (@name, @password) ->
        @tableTokens = {}
        @sourceSystemTokens = {}

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

    @getTableToken: (user, sourceSystem, done) ->
        if user.tableTokens[sourceSystem]?
            done null, user.tableTokens[sourceSystem]
            return
        TokenManager.createTableToken user.token, sourceSystem, (err, tableToken) ->
            if err?
                done err, null
                return
            user.tableTokens[sourceSystem] = tableToken
            done null, tableToken

    @getSourceSystemToken: (user, sourceSystem, done) ->
        if user.sourceSystemTokens[sourceSystem]?
            done null, user.sourceSystemTokens[sourceSystem]
            return
        TokenManager.createSourceSystemToken user.token, sourceSystem, (err, sourceSystemToken) ->
            if err?
                done err, null
                return
            user.sourceSystemTokens[sourceSystem] = sourceSystemToken
            done null, sourceSystemToken


module.exports = User
