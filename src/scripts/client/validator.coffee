app = require './virtdb-app.js'

module.exports = app.factory 'Validator', [ ->
    new class Validator
        constructor: () ->

        validatePassword: (pass1, pass2) =>
            if pass1 isnt pass2
               return new Error "Password is not matching with its confirmation"
            if not pass1? or pass1.length is 0
                return new Error "Password is empty"
            return null

        validateName: (name) =>
            if name?.length is 0
                return new Error "Username is empty"
            return null
]
