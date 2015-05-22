TokenManager = require './token_manager'

class User
    token: null
    constructor: (@name, @password) ->
    authenticate: (done) =>
        TokenManager.createLoginToken @name, @password, (err, user) =>
            if err?
                done null, false, {message: err.toString()}
                return
            @password = null
            @token = user.LoginToken
            @isAdmin = user.Data.IsAdmin
            done null, @
            return

module.exports = User
