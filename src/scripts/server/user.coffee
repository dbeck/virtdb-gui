TokenManager = require './token_manager'

class User

    token: null

    constructor: (@name, @password) ->

    authenticate: (done) =>
        tokenManager = new TokenManager
        tokenManager.createLoginToken @name, @password, (err, token) =>
            if err?
                done null, false, {message: err.message}
                return
            @token = token
            # @password = null
            done null, @
            return
        
module.exports = User
