(require "source-map-support").install()
UserManagerConnection = require './user_manager_connection'
log = (require "virtdb-connector").log
V_ = log.Variable
ReportError = require "./report-error"

class UserManager
    constructor: ->

    createUser: (username, password, isAdmin, token, done) =>
        request = 
            Type: "CREATE_USER"
            CrUser:
                UserName: username
                Password: password
                IsAdmin: isAdmin
                LoginToken: token
        connection = new UserManagerConnection
        connection.send request, (reply) =>
            if not (ReportError reply, done)
                done null, null
    
    updateUser: (username, password, isAdmin, token, done) =>
        request = 
            Type: "UPDATE_USER"
            UpdUser:    
                UserName: username
                Password: password
                IsAdmin: isAdmin
                LoginToken: token
        connection = new UserManagerConnection
        connection.send request, (reply) =>
            if not (ReportError reply, done)
                done null, null

    deleteUser: (username, token, done) =>
        request = 
            Type: "DELETE_USER"
            DelUser:
                UserName: username
                LoginToken: token
        connection = new UserManagerConnection
        connection.send request, (reply) =>
            if not (ReportError reply, done)
                done null, null

    listUsers: (token, done) =>
        request = 
            Type: "LIST_USERS"
            LstUsers:
                LoginToken: token
        connection = new UserManagerConnection
        connection.send request, (reply) =>
            if not (ReportError reply, done)
                console.log reply
                done null, reply.LstUsers.Users

module.exports = UserManager
