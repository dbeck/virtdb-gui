class UserManager
    constructor: ->

    createUser: (username, password, isAdmin, token, done) =>
        request = 
            RequestType: "CREATE_USER"
            CrUser:
                UserName: username
                Password: password
                IsAdmin: isAdmin
                LoginToken: token
    
    updateUser: (username, password, isAdmin, token, done) =>
        request = 
            RequestType: "UPDATE_USER"
            UpdUser:    
                UserName: username
                Password: password
                IsAdmin: isAdmin
                LoginToken: token                

    deleteUser: (username, password, isAdmin, token, done) =>
        request = 
            RequestType: "DELETE_USER"
            DelUser:
                UserName: username
                LoginToken: @user.loginToken

    listUsers: (token, done) =>
        request = 
            RequestType: "LIST_USERS"
            LstUsers:
                LoginToken: token

module.exports = UserManager
