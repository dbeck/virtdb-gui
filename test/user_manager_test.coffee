require("source-map-support").install()
UserManager = require "../src/scripts/server/user_manager"
Endpoints = require "../src/scripts/server/endpoints"
SocketStub = require "./socket_stub"
zmq     = require 'zmq'
SecurityProto = (require "virtdb-proto").security

chai = require "chai"
should = chai.should()
sinon = require "sinon"
sinonChai = require "sinon-chai"
chai.use sinonChai

describe "UserManager", ->
    sandbox = null
    socket = null
    connectStub = null

    beforeEach =>
        sandbox = sinon.sandbox.create()
        sandbox.stub Endpoints, "getUserManagerAddress", () =>
            return ["ADDR1", "ADDR2"]
        socket = new SocketStub
        connectStub = sandbox.stub zmq, "socket", (type) ->
            type.should.equal 'req'
            return socket
        sandbox.stub (require "virtdb-connector").log, "error"

    afterEach =>
        sandbox.restore()

    describe "createUser", ->

        it "should send good UserManagerRequest", ->
            USER = "user"
            PASS = "pass"
            IS_ADMIN = true
            TOKEN = "token-sfsfs-sfs-sf"
            REQUEST =
                Type: "CREATE_USER"
                CrUser:
                    UserName: USER
                    Password: PASS
                    IsAdmin: IS_ADMIN
                    LoginToken: TOKEN

            SER_REQUEST = SecurityProto.serialize REQUEST, "virtdb.interface.pb.UserManagerRequest"

            callback = sinon.spy()
            userManager = new UserManager
            userManager.createUser USER, PASS, IS_ADMIN, TOKEN, callback
            socket.send.should.have.been.calledWithExactly SER_REQUEST

        it "should receive UserManagerReply", ->
            REPLY =
                Type: "CREATE_USER"
            SER_REPLY = SecurityProto.serialize REPLY, "virtdb.interface.pb.UserManagerReply"

            callback = sinon.spy()

            userManager = new UserManager
            userManager.createUser "user", "pass", true, "token", callback
            socket.receive SER_REPLY

            callback.should.be.calledWithExactly null, null

        it "should receive error when security service replied with error", ->
            ERROR_TEXT = "WRONG PASSWOR"
            REPLY =
                Type: "ERROR_MSG"
                Err:
                    Msg: ERROR_TEXT
            callback = sinon.spy()
            userManager = new UserManager
            userManager.createUser "user", "pass", true, "token", callback
            socket.receive SecurityProto.serialize REPLY, "virtdb.interface.pb.UserManagerReply"

            callback.should.be.calledWithExactly sinon.match.has("message", ERROR_TEXT), null

        it "should receive error when couldn't communicate with security service", ->
            REQUEST =
                Type: "kiscica"

            callback = sinon.spy()
            userManager = new UserManager
            userManager.createUser "user", "pass", true, "token", callback
            socket.receive REQUEST

            callback.should.be.calledWithExactly sinon.match.defined, null

    describe "deleteUser", ->

        it "should send good UserManagerRequest", ->
            USER = "user"
            TOKEN = "token-sfsfs-sfs-sf"
            REQUEST =
                Type: "DELETE_USER"
                DelUser:
                    UserName: USER
                    LoginToken: TOKEN

            SER_REQUEST = SecurityProto.serialize REQUEST, "virtdb.interface.pb.UserManagerRequest"

            callback = sinon.spy()
            userManager = new UserManager
            userManager.deleteUser USER, TOKEN, callback
            socket.send.should.have.been.calledWithExactly SER_REQUEST

        it "should receive UserManagerReply", ->
            REPLY =
                Type: "DELETE_USER"
            SER_REPLY = SecurityProto.serialize REPLY, "virtdb.interface.pb.UserManagerReply"

            callback = sinon.spy()

            userManager = new UserManager
            userManager.deleteUser "user", "token", callback
            socket.receive SER_REPLY

            callback.should.be.calledWithExactly null, null

        it "should receive error when security service replied with error", ->
            ERROR_TEXT = "WRONG PASSWOR"
            REPLY =
                Type: "ERROR_MSG"
                Err:
                    Msg: ERROR_TEXT
            callback = sinon.spy()
            userManager = new UserManager
            userManager.deleteUser "user", "token", callback
            socket.receive SecurityProto.serialize REPLY, "virtdb.interface.pb.UserManagerReply"

            callback.should.be.calledWithExactly sinon.match.has("message", ERROR_TEXT), null

        it "should receive error when couldn't communicate with security service", ->
            REQUEST =
                Type: "kiscica"

            callback = sinon.spy()
            userManager = new UserManager
            userManager.deleteUser "user", "token", callback
            socket.receive REQUEST

            callback.should.be.calledWithExactly sinon.match.defined, null

    describe "updateUser", ->

        it "should send good UserManagerRequest", ->
            USER = "user"
            PASS = "pass"
            IS_ADMIN = true
            TOKEN = "token-sfsfs-sfs-sf"
            REQUEST =
                Type: "UPDATE_USER"
                UpdUser:
                    UserName: USER
                    Password: PASS
                    IsAdmin: IS_ADMIN
                    LoginToken: TOKEN

            SER_REQUEST = SecurityProto.serialize REQUEST, "virtdb.interface.pb.UserManagerRequest"

            callback = sinon.spy()
            userManager = new UserManager
            userManager.updateUser USER, PASS, IS_ADMIN, TOKEN, callback
            socket.send.should.have.been.calledWithExactly SER_REQUEST

        it "should receive UserManagerReply", ->
            REPLY =
                Type: "UPDATE_USER"
            SER_REPLY = SecurityProto.serialize REPLY, "virtdb.interface.pb.UserManagerReply"

            callback = sinon.spy()

            userManager = new UserManager
            userManager.updateUser "user", "pass", true, "token", callback
            socket.receive SER_REPLY

            callback.should.be.calledWithExactly null, null

        it "should receive error when security service replied with error", ->
            ERROR_TEXT = "WRONG PASSWOR"
            REPLY =
                Type: "ERROR_MSG"
                Err:
                    Msg: ERROR_TEXT
            callback = sinon.spy()
            userManager = new UserManager
            userManager.updateUser "user", "pass", true, "token", callback
            socket.receive SecurityProto.serialize REPLY, "virtdb.interface.pb.UserManagerReply"

            callback.should.be.calledWithExactly sinon.match.has("message", ERROR_TEXT), null

        it "should receive error when couldn't communicate with security service", ->
            REQUEST =
                Type: "kiscica"

            callback = sinon.spy()
            userManager = new UserManager
            userManager.updateUser "user", "pass", true, "token", callback
            socket.receive REQUEST

            callback.should.be.calledWithExactly sinon.match.defined, null

    describe "listUsers", ->

        it "should send good UserManagerRequest", ->
            USER = "user"
            PASS = "pass"
            IS_ADMIN = true
            TOKEN = "token-sfsfs-sfs-sf"
            REQUEST =
                Type: "LIST_USERS"
                LstUsers:
                    UserName: USER
                    Password: PASS
                    IsAdmin: IS_ADMIN
                    LoginToken: TOKEN

            SER_REQUEST = SecurityProto.serialize REQUEST, "virtdb.interface.pb.UserManagerRequest"

            callback = sinon.spy()
            userManager = new UserManager
            userManager.listUsers TOKEN, callback
            socket.send.should.be.calledWithExactly SER_REQUEST

        it "should receive UserManagerReply", ->
            USERS = [
                Name: "user1"
                PassHash: "hash1"
                Salt: 43
                IsAdmin: true
                LoginTokens: ["token1", "token2"]
                TableTokens: ["tt1", "tt2"]
                SourceSysTokens: ["sst1", "sst2"]
            ,
                Name: "user2"
                PassHash: "hash2"
                Salt: 67
                IsAdmin: false
                LoginTokens: ["token4", "token5"]
                TableTokens: ["tt4", "tt5"]
                SourceSysTokens: ["sst4", "sst5"]
            ]

            REPLY =
                Type: "LIST_USERS"
                LstUsers:
                    Users: USERS
            SER_REPLY = SecurityProto.serialize REPLY, "virtdb.interface.pb.UserManagerReply"

            callback = sinon.spy()

            userManager = new UserManager
            userManager.listUsers "token", callback
            socket.receive SER_REPLY

            callback.should.be.calledWithExactly null, USERS

        it "should receive error when security service replied with error", ->
            ERROR_TEXT = "WRONG PASSWOR"
            REPLY =
                Type: "ERROR_MSG"
                Err:
                    Msg: ERROR_TEXT
            callback = sinon.spy()
            userManager = new UserManager
            userManager.listUsers "token", callback
            socket.receive SecurityProto.serialize REPLY, "virtdb.interface.pb.UserManagerReply"

            callback.should.be.calledWithExactly sinon.match.has("message", ERROR_TEXT), null

        it "should receive error when couldn't communicate with security service", ->
            REQUEST =
                Type: "kiscica"

            callback = sinon.spy()
            userManager = new UserManager
            userManager.listUsers "token", callback
            socket.receive REQUEST

            callback.should.be.calledWithExactly sinon.match.defined, null