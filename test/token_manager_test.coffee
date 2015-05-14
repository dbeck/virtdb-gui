TokenManager = require "../src/scripts/server/token_manager"
Endpoints = require "../src/scripts/server/endpoints"
zmq     = require 'zmq'
SecurityProto = (require "virtdb-proto").security
VirtDBConnector = require 'virtdb-connector'

chai = require "chai"
should = chai.should()
sinon = require "sinon"
sinonChai = require "sinon-chai"
chai.use sinonChai

describe "TokenManager", ->
    sandbox = null
    connectStub = null

    beforeEach =>
        sandbox = sinon.sandbox.create()
        sandbox.stub Endpoints, "getUserManagerAddress", () =>
            return ["ADDR1", "ADDR2"]
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
            sendRequest = sandbox.stub VirtDBConnector, 'sendRequest'
            TokenManager.createLoginToken USER, PASS, callback
            sendRequest.should.have.calledWith "security-service", "USER_MGR", SER_REQUEST

        it "should receive UserManagerReply", ->
            LOGIN_TOKEN = "logisnsgngg-tokensn"
            REPLY =
                Type: "CREATE_LOGIN_TOKEN"
                CrLoginTok:
                    LoginToken: LOGIN_TOKEN
            SER_REPLY = SecurityProto.serialize REPLY, "virtdb.interface.pb.UserManagerReply"

            callback = sinon.spy()
            sendRequest = sandbox.stub VirtDBConnector, 'sendRequest'

            TokenManager.createLoginToken "user", "pass", callback
            sendRequest.callArgWith 3, null, SER_REPLY

            callback.should.be.calledWithExactly null, LOGIN_TOKEN

        it "should receive error when security service replied with error", ->
            ERROR_TEXT = "WRONG PASSWORD"
            REPLY =
                Type: "ERROR_MSG"
                Err:
                    Msg: ERROR_TEXT
            SER_REPLY = SecurityProto.serialize REPLY, "virtdb.interface.pb.UserManagerReply"

            callback = sinon.spy()
            sendRequest = sandbox.stub VirtDBConnector, 'sendRequest'
            TokenManager.createLoginToken "user", "pass", callback
            sendRequest.callArgWith 3, null, SER_REPLY

            callback.should.be.calledWith new Error "Error: #{ERROR_TEXT}", null

        it "should receive error when couldn't communicate with security service", ->
            REQUEST =
                Type: "kiscica"

            callback = sinon.spy()
            sendRequest = sandbox.stub VirtDBConnector, 'sendRequest'
            TokenManager.createLoginToken "user", "pass", callback
            sendRequest.callArgWith 3, null, REQUEST

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
            sendRequest = sandbox.stub VirtDBConnector, 'sendRequest'
            TokenManager.createSourceSystemToken TOKEN, SOURCE_SYS_NAME, callback
            sendRequest.should.have.been.calledWith 'security-service', 'USER_MGR', SER_REQUEST

        it "should receive UserManagerReply", ->

            SOURCE_SYTEM_TOKEN = "some-good-token"
            REPLY =
                Type: "CREATE_LOGIN_TOKEN"
                CrSSTok:
                    SourceSysToken: SOURCE_SYTEM_TOKEN
            SER_REPLY = SecurityProto.serialize REPLY, "virtdb.interface.pb.UserManagerReply"

            callback = sinon.spy()
            sendRequest = sandbox.stub VirtDBConnector, 'sendRequest'

            TokenManager.createSourceSystemToken "token", "ssys", callback
            sendRequest.callArgWith 3, null, SER_REPLY

            callback.should.be.calledWithExactly null, SOURCE_SYTEM_TOKEN

        it "should receive error when security service replied with error", ->
            ERROR_TEXT = "WRONG PASSWORD"
            REPLY =
                Type: "ERROR_MSG"
                Err:
                    Msg: ERROR_TEXT
            SER_REPLY = SecurityProto.serialize REPLY, "virtdb.interface.pb.UserManagerReply"

            callback = sinon.spy()
            sendRequest = sandbox.stub VirtDBConnector, 'sendRequest'
            TokenManager.createSourceSystemToken "token", "ssys", callback
            sendRequest.callArgWith 3, null, SER_REPLY

            callback.should.be.calledWith new Error "Error: #{ERROR_TEXT}", null

        it "should receive error when couldn't communicate with security service", ->
            REQUEST =
                Type: "kiscica"

            callback = sinon.spy()
            sendRequest = sandbox.stub VirtDBConnector, 'sendRequest'
            TokenManager.createSourceSystemToken "token", "ssys", callback
            sendRequest.callArgWith 3, null, REQUEST

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
            sendRequest = sandbox.stub VirtDBConnector, 'sendRequest'
            TokenManager.getSourceSystemToken TOKEN, SOURCE_SYS_NAME, callback
            sendRequest.should.have.been.calledWith 'security-service', 'USER_MGR', SER_REQUEST

        it "should receive UserManagerReply", ->

            SOURCE_SYTEM_TOKEN = "some-good-token"
            REPLY =
                Type: "CREATE_LOGIN_TOKEN"
                GetSSTok:
                    SourceSysToken: SOURCE_SYTEM_TOKEN
            SER_REPLY = SecurityProto.serialize REPLY, "virtdb.interface.pb.UserManagerReply"

            callback = sinon.spy()
            sendRequest = sandbox.stub VirtDBConnector, 'sendRequest'

            TokenManager.getSourceSystemToken "token", "ssys", callback
            sendRequest.callArgWith 3, null, SER_REPLY

            callback.should.be.calledWithExactly null, SOURCE_SYTEM_TOKEN

        it "should receive error when security service replied with error", ->
            ERROR_TEXT = "WRONG PASSWOR"
            REPLY =
                Type: "ERROR_MSG"
                Err:
                    Msg: ERROR_TEXT
            SER_REPLY = SecurityProto.serialize REPLY, "virtdb.interface.pb.UserManagerReply"

            callback = sinon.spy()
            sendRequest = sandbox.stub VirtDBConnector, 'sendRequest'
            TokenManager.getSourceSystemToken "token", "ssys", callback
            sendRequest.callArgWith 3, null, SER_REPLY

            callback.should.be.calledWith new Error "Error: #{ERROR_TEXT}", null

        it "should receive error when couldn't communicate with security service", ->
            REQUEST =
                Type: "kiscica"

            callback = sinon.spy()
            sendRequest = sandbox.stub VirtDBConnector, 'sendRequest'
            TokenManager.getSourceSystemToken "token", "ssys", callback
            sendRequest.callArgWith 3, null, REQUEST

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
            sendRequest = sandbox.stub VirtDBConnector, 'sendRequest'
            TokenManager.createTableToken TOKEN, SOURCE_SYS_NAME, callback
            sendRequest.should.have.been.calledWith 'security-service', 'USER_MGR', SER_REQUEST

        it "should receive UserManagerReply", ->

            TABLE_TOKEN = "some-good-token"
            REPLY =
                Type: "CREATE_TABLE_TOKEN"
                CrTabTok:
                    TableToken: TABLE_TOKEN
            SER_REPLY = SecurityProto.serialize REPLY, "virtdb.interface.pb.UserManagerReply"

            callback = sinon.spy()
            sendRequest = sandbox.stub VirtDBConnector, 'sendRequest'

            TokenManager.createTableToken "token", "ssys", callback
            sendRequest.callArgWith 3, null, SER_REPLY

            callback.should.be.calledWithExactly null, TABLE_TOKEN

        it "should receive error when security service replied with error", ->
            ERROR_TEXT = "WRONG PASSWOR"
            REPLY =
                Type: "ERROR_MSG"
                Err:
                    Msg: ERROR_TEXT
            SER_REPLY = SecurityProto.serialize REPLY, "virtdb.interface.pb.UserManagerReply"

            callback = sinon.spy()
            sendRequest = sandbox.stub VirtDBConnector, 'sendRequest'
            TokenManager.createTableToken "token", "ssys", callback
            sendRequest.callArgWith 3, null, SER_REPLY

            callback.should.be.calledWith new Error "Error: #{ERROR_TEXT}", null

        it "should receive error when couldn't communicate with security service", ->
            REQUEST =
                Type: "kiscica"

            callback = sinon.spy()
            sendRequest = sandbox.stub VirtDBConnector, 'sendRequest'
            TokenManager.createTableToken "token", "ssys", callback
            sendRequest.callArgWith 3, null, REQUEST

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
            sendRequest = sandbox.stub VirtDBConnector, 'sendRequest'
            TokenManager.deleteToken LOGIN_TOKEN, ANY_TOKEN, callback
            sendRequest.should.have.been.calledWith 'security-service', 'USER_MGR', SER_REQUEST

        it "should receive UserManagerReply", ->
            REPLY =
                Type: "DELETE_TOKEN"
            SER_REPLY = SecurityProto.serialize REPLY, "virtdb.interface.pb.UserManagerReply"

            callback = sinon.spy()
            sendRequest = sandbox.stub VirtDBConnector, 'sendRequest'

            TokenManager.deleteToken "token", "token22", callback
            sendRequest.callArgWith 3, null, SER_REPLY

            callback.should.be.calledWithExactly null, null

        it "should receive error when security service replied with error", ->
            ERROR_TEXT = "WRONG PASSWOR"
            REPLY =
                Type: "ERROR_MSG"
                Err:
                    Msg: ERROR_TEXT
            SER_REPLY = SecurityProto.serialize REPLY, "virtdb.interface.pb.UserManagerReply"

            callback = sinon.spy()
            sendRequest = sandbox.stub VirtDBConnector, 'sendRequest'
            TokenManager.deleteToken "token", "token22", callback
            sendRequest.callArgWith 3, null, SER_REPLY

            callback.should.be.calledWith new Error "Error: #{ERROR_TEXT}", null

        it "should receive error when couldn't communicate with security service", ->
            REQUEST =
                Type: "kiscica"

            callback = sinon.spy()
            sendRequest = sandbox.stub VirtDBConnector, 'sendRequest'
            TokenManager.deleteToken "token", "token22", callback
            sendRequest.callArgWith 3, null, REQUEST

            callback.should.be.calledWithExactly sinon.match.defined, null

