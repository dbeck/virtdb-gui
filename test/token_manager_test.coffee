require("source-map-support").install()
TokenManager = require "../src/scripts/server/token_manager"
Endpoints = require "../src/scripts/server/endpoints"
SocketStub = require "./socket_stub"
zmq     = require 'zmq'
SecurityProto = (require "virtdb-proto").security

chai = require "chai"
should = chai.should()
sinon = require "sinon"
sinonChai = require "sinon-chai"
chai.use sinonChai

describe "TokenManager", ->
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

    describe "createLoginToken", ->

        it "should send good UserManagerRequest", ->
            USER = "user"
            PASS = "pass"
            REQUEST = 
                Type: "CREATE_LOGIN_TOKEN"
                CrLoginTok:
                    UserName: USER
                    Password: PASS
            SER_REQUEST = SecurityProto.serialize REQUEST, "virtdb.interface.pb.UserManagerRequest"

            callback = sinon.spy()
            tokenManager = new TokenManager
            tokenManager.createLoginToken USER, PASS, callback
            socket.send.should.have.been.calledWithExactly SER_REQUEST
        
        it "should receive UserManagerReply", ->
            LOGIN_TOKEN = "logisnsgngg-tokensn"
            REPLY =
                Type: "CREATE_LOGIN_TOKEN"
                CrLoginTok:
                    LoginToken: LOGIN_TOKEN
            SER_REPLY = SecurityProto.serialize REPLY, "virtdb.interface.pb.UserManagerReply"

            callback = sinon.spy()
            
            tokenManager = new TokenManager
            tokenManager.createLoginToken "user", "pass", callback
            socket.receive SER_REPLY

            callback.should.be.calledWithExactly null, LOGIN_TOKEN    
        
        it "should receive error when security service replied with error", ->
            ERROR_TEXT = "WRONG PASSWOR"
            REPLY =
                Type: "ERROR_MSG"
                Err:
                    Msg: ERROR_TEXT
            SER_REPLY = SecurityProto.serialize REPLY, "virtdb.interface.pb.UserManagerReply"

            callback = sinon.spy()
            tokenManager = new TokenManager
            tokenManager.createLoginToken "user", "pass", callback
            socket.receive SER_REPLY

            callback.should.be.calledWithExactly sinon.match.has("message", ERROR_TEXT), null    

        it "should receive error when couldn't communicate with security service", ->
            REQUEST = 
                Type: "kiscica"

            callback = sinon.spy()
            tokenManager = new TokenManager
            tokenManager.createLoginToken "user", "pass", callback
            socket.receive REQUEST

            callback.should.be.calledWithExactly sinon.match.defined, null

    describe "createSourceSystemToken", ->

        it "should send good UserManagerRequest", ->
            TOKEN = "sfgdhtdsesrhdtg"
            SOURCE_SYS_NAME = "some-good-system"
            REQUEST = 
                Type: "CREATE_SOURCESYS_TOKEN"
                CrSSTok:
                    LoginToken: TOKEN
                    SourceSysName: SOURCE_SYS_NAME
            SER_REQUEST = SecurityProto.serialize REQUEST, "virtdb.interface.pb.UserManagerRequest"

            callback = sinon.spy()
            tokenManager = new TokenManager
            tokenManager.createSourceSystemToken TOKEN, SOURCE_SYS_NAME, callback
            socket.send.should.have.been.calledWithExactly SER_REQUEST

        it "should receive UserManagerReply", ->

            SOURCE_SYTEM_TOKEN = "some-good-token"
            REPLY =
                Type: "CREATE_LOGIN_TOKEN"
                CrSSTok:
                    SourceSysToken: SOURCE_SYTEM_TOKEN
            SER_REPLY = SecurityProto.serialize REPLY, "virtdb.interface.pb.UserManagerReply"

            callback = sinon.spy()
            
            tokenManager = new TokenManager
            tokenManager.createSourceSystemToken "token", "ssys", callback
            socket.receive SER_REPLY

            callback.should.be.calledWithExactly null, SOURCE_SYTEM_TOKEN    

        it "should receive error when security service replied with error", ->
            ERROR_TEXT = "WRONG PASSWOR"
            REPLY =
                Type: "ERROR_MSG"
                Err:
                    Msg: ERROR_TEXT
            SER_REPLY = SecurityProto.serialize REPLY, "virtdb.interface.pb.UserManagerReply"

            callback = sinon.spy()
            tokenManager = new TokenManager
            tokenManager.createSourceSystemToken "token", "ssys", callback
            socket.receive SER_REPLY

            callback.should.be.calledWithExactly sinon.match.has("message", ERROR_TEXT), null    

        it "should receive error when couldn't communicate with security service", ->
            REQUEST = 
                Type: "kiscica"

            callback = sinon.spy()
            tokenManager = new TokenManager
            tokenManager.createSourceSystemToken "token", "ssys", callback
            socket.receive REQUEST

            callback.should.be.calledWithExactly sinon.match.defined, null
    
    describe "getSourceSystemToken", ->

        it "should send good UserManagerRequest", ->
            TOKEN = "sfgdhtdsesrhdtg"
            SOURCE_SYS_NAME = "some-good-system"
            REQUEST = 
                Type: "GET_SOURCESYS_TOKEN"
                GetSSTok:
                    LoginOrTableToken: TOKEN
                    SourceSysName: SOURCE_SYS_NAME
            SER_REQUEST = SecurityProto.serialize REQUEST, "virtdb.interface.pb.UserManagerRequest"

            callback = sinon.spy()
            tokenManager = new TokenManager
            tokenManager.getSourceSystemToken TOKEN, SOURCE_SYS_NAME, callback
            socket.send.should.have.been.calledWithExactly SER_REQUEST

        it "should receive UserManagerReply", ->

            SOURCE_SYTEM_TOKEN = "some-good-token"
            REPLY =
                Type: "CREATE_LOGIN_TOKEN"
                GetSSTok:
                    SourceSysToken: SOURCE_SYTEM_TOKEN
            SER_REPLY = SecurityProto.serialize REPLY, "virtdb.interface.pb.UserManagerReply"

            callback = sinon.spy()
            
            tokenManager = new TokenManager
            tokenManager.getSourceSystemToken "token", "ssys", callback
            socket.receive SER_REPLY

            callback.should.be.calledWithExactly null, SOURCE_SYTEM_TOKEN    

        it "should receive error when security service replied with error", ->
            ERROR_TEXT = "WRONG PASSWOR"
            REPLY =
                Type: "ERROR_MSG"
                Err:
                    Msg: ERROR_TEXT
            SER_REPLY = SecurityProto.serialize REPLY, "virtdb.interface.pb.UserManagerReply"

            callback = sinon.spy()
            tokenManager = new TokenManager
            tokenManager.getSourceSystemToken "token", "ssys", callback
            socket.receive SER_REPLY

            callback.should.be.calledWithExactly sinon.match.has("message", ERROR_TEXT), null    

        it "should receive error when couldn't communicate with security service", ->
            REQUEST = 
                Type: "kiscica"

            callback = sinon.spy()
            tokenManager = new TokenManager
            tokenManager.getSourceSystemToken "token", "ssys", callback
            socket.receive REQUEST

            callback.should.be.calledWithExactly sinon.match.defined, null
    
    describe "createTableToken", ->

        it "should send good UserManagerRequest", ->
            TOKEN = "sfgdhtdsesrhdtg"
            SOURCE_SYS_NAME = "some-good-system"
            REQUEST = 
                Type: "CREATE_TABLE_TOKEN"
                CrTabTok:
                    LoginToken: TOKEN
                    SourceSysName: SOURCE_SYS_NAME
            SER_REQUEST = SecurityProto.serialize REQUEST, "virtdb.interface.pb.UserManagerRequest"

            callback = sinon.spy()
            tokenManager = new TokenManager
            tokenManager.createTableToken TOKEN, SOURCE_SYS_NAME, callback
            socket.send.should.have.been.calledWithExactly SER_REQUEST

        it "should receive UserManagerReply", ->

            TABLE_TOKEN = "some-good-token"
            REPLY =
                Type: "CREATE_TABLE_TOKEN"
                CrTabTok:
                    TableToken: TABLE_TOKEN
            SER_REPLY = SecurityProto.serialize REPLY, "virtdb.interface.pb.UserManagerReply"

            callback = sinon.spy()
            
            tokenManager = new TokenManager
            tokenManager.createTableToken "token", "ssys", callback
            socket.receive SER_REPLY

            callback.should.be.calledWithExactly null, TABLE_TOKEN    

        it "should receive error when security service replied with error", ->
            ERROR_TEXT = "WRONG PASSWOR"
            REPLY =
                Type: "ERROR_MSG"
                Err:
                    Msg: ERROR_TEXT
            SER_REPLY = SecurityProto.serialize REPLY, "virtdb.interface.pb.UserManagerReply"

            callback = sinon.spy()
            tokenManager = new TokenManager
            tokenManager.createTableToken "token", "ssys", callback
            socket.receive SER_REPLY

            callback.should.be.calledWithExactly sinon.match.has("message", ERROR_TEXT), null    

        it "should receive error when couldn't communicate with security service", ->
            REQUEST = 
                Type: "kiscica"

            callback = sinon.spy()
            tokenManager = new TokenManager
            tokenManager.createTableToken "token", "ssys", callback
            socket.receive REQUEST

            callback.should.be.calledWithExactly sinon.match.defined, null
    
   
    describe "deleteToken", ->

        it "should send good UserManagerRequest", ->
            LOGIN_TOKEN = "sfgdhtdsesrhdtg"
            ANY_TOKEN = "hyhyhyhfdsfsfsf;;;;;"
            REQUEST = 
                Type: "DELETE_TOKEN"
                DelTok:
                    LoginToken: LOGIN_TOKEN
                    AnyTokenValue: ANY_TOKEN
            SER_REQUEST = SecurityProto.serialize REQUEST, "virtdb.interface.pb.UserManagerRequest"

            callback = sinon.spy()
            tokenManager = new TokenManager
            tokenManager.deleteToken LOGIN_TOKEN, ANY_TOKEN, callback
            socket.send.should.have.been.calledWithExactly SER_REQUEST

        it "should receive UserManagerReply", ->
            REPLY =
                Type: "DELETE_TOKEN"
            SER_REPLY = SecurityProto.serialize REPLY, "virtdb.interface.pb.UserManagerReply"

            callback = sinon.spy()
            
            tokenManager = new TokenManager
            tokenManager.deleteToken "token", "token22", callback
            socket.receive SER_REPLY

            callback.should.be.calledWithExactly null, null    

        it "should receive error when security service replied with error", ->
            ERROR_TEXT = "WRONG PASSWOR"
            REPLY =
                Type: "ERROR_MSG"
                Err:
                    Msg: ERROR_TEXT
            SER_REPLY = SecurityProto.serialize REPLY, "virtdb.interface.pb.UserManagerReply"

            callback = sinon.spy()
            tokenManager = new TokenManager
            tokenManager.deleteToken "token", "token22", callback
            socket.receive SER_REPLY

            callback.should.be.calledWithExactly sinon.match.has("message", ERROR_TEXT), null    

        it "should receive error when couldn't communicate with security service", ->
            REQUEST = 
                Type: "kiscica"

            callback = sinon.spy()
            tokenManager = new TokenManager
            tokenManager.deleteToken "token", "token22", callback
            socket.receive REQUEST

            callback.should.be.calledWithExactly sinon.match.defined, null
    
