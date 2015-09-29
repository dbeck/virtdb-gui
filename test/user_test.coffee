require("source-map-support").install()
TokenManager = (require "virtdb-connector").TokenManager
Endpoints = require "../src/scripts/server/endpoints"
User = require "../src/scripts/server/user"
SocketStub = require "./socket_stub"
SecurityProto = (require "virtdb-proto").security
zmq = require "zmq"

chai = require "chai"
should = chai.should()
sinon = require "sinon"
sinonChai = require "sinon-chai"
chai.use sinonChai

describe "User", ->
    sandbox = null
    socket = null

    beforeEach =>
        sandbox = sinon.sandbox.create()
        socket = new SocketStub
        sandbox.stub Endpoints, "getUserManagerAddress", () =>
            return ["ADDR1", "ADDR2"]
        sandbox.stub zmq, "socket", (type) ->
            type.should.equal 'req'
            return socket
        sandbox.stub (require "virtdb-connector").log, "error"

    afterEach =>
        sandbox.restore()

    it "should give back the user when authentication was succesful", ->
        USER =
            LoginToken: "tokensgslgnskgsk"
            Data:
                Name: "user"
                PassHash: "sfsfsfs"
                IsAdmin: true
        createLoginToken = sandbox.stub TokenManager, "createLoginToken"
        done = sandbox.spy()
        user = new User("user", "pass")
        user.authenticate(done)
        createLoginToken.callArgWith 2, null, USER

        done.should.have.been.calledWithExactly null, user

    it "should not give back the user when authentication failed", ->
        ERROR_TEXT = "WRONG PASSWORD"
        createLoginToken = sandbox.stub TokenManager, "createLoginToken"
        done = sandbox.spy()
        user = new User("user", "pass")
        user.authenticate(done)
        createLoginToken.callArgWith 2, new Error ERROR_TEXT, null

        done.should.have.been.calledWithExactly null, false, {message: "Error: #{ERROR_TEXT}"}

    it "should be able to get tableToken for a source system", ->
        SRC_SYS = "src-sys"
        TT = "tableToken1"
        USER =
            LoginToken: "tokensgslgnskgsk"
            Data:
                Name: "user"
                PassHash: "sfsfsfs"
                IsAdmin: true
        createLoginToken = sandbox.stub TokenManager, "createLoginToken"
        createLoginToken.yields null, USER
        createTableToken = sandbox.stub TokenManager, 'createTableToken'
        createTableToken.yields null, 'tableToken1'

        user = new User("user", "pass")
        user.authenticate()

        done = sandbox.spy()
        User.getTableToken user, SRC_SYS, done
        done.should.have.been.calledOnce
        done.should.have.been.calledWithExactly null, TT

        secondCall = sandbox.spy()
        User.getTableToken user, SRC_SYS, secondCall
        secondCall.should.have.been.calledOnce
        secondCall.should.have.been.calledWithExactly null, TT

        createTableToken.should.have.been.calledOnce
