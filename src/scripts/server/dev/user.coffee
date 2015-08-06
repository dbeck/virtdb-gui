offline = (require './config').getCommandLineParameter('offline')
TokenManager = (require "virtdb-connector").TokenManager

class User

    tableTokens: null
    sourceSystemTokens: null
    token: null

    constructor: (@name, @password) ->
        @tableTokens = {}
        @sourceSystemTokens = {}

    authenticate: (done) =>
        @password = null
        @token = 'dummyToken'
        @tableTokens = {}
        @isAdmin = true
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

module.exports = User
