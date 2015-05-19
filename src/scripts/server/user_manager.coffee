(require "source-map-support").install()
VirtDB = require 'virtdb-connector'
Const = VirtDB.Const
log = VirtDB.log
V_ = log.Variable

sendSecurityMessage = (require './protocol').sendSecurityMessage

class UserManager

    @createUser: (username, password, isAdmin, token, done) =>
        request =
            Type: "CREATE_USER"
            CrUser:
                UserName: username
                Password: password
                IsAdmin: isAdmin
                LoginToken: token

        sendSecurityMessage Const.ENDPOINT_TYPE.USER_MGR, request, (err, message) ->
            done err, null

    @updateUser: (username, password, isAdmin, token, done) =>
        request =
            Type: "UPDATE_USER"
            UpdUser:
                UserName: username
                Password: password
                IsAdmin: isAdmin
                LoginToken: token

        sendSecurityMessage Const.ENDPOINT_TYPE.USER_MGR, request, (err, message) ->
            done err, null

    @deleteUser: (username, token, done) =>
        request =
            Type: "DELETE_USER"
            DelUser:
                UserName: username
                LoginToken: token

        sendSecurityMessage Const.ENDPOINT_TYPE.USER_MGR, request, (err, message) ->
            done err, null

    @listUsers: (token, done) =>
        request =
            Type: "LIST_USERS"
            LstUsers:
                LoginToken: token

        sendSecurityMessage Const.ENDPOINT_TYPE.USER_MGR, request, (err, message) ->
            data = null
            if not err? and message?.LstUsers?.Users?
                data = message.LstUsers.Users
            done err, data

module.exports = UserManager
