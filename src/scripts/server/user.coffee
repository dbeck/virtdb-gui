TokenManager = require './token_manager'

class User
    token: null
    constructor: (@name, @password) ->
    authenticate: (done) =>
        TokenManager.createLoginToken @name, @password, (err, token) =>
            if err?
                done null, false, {message: err.toString()}
                return
            @password = null
            @token = token
            done null, @
            return

module.exports = User
