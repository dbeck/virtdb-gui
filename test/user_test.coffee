require("source-map-support").install()
TokenManager = require "../src/scripts/server/token_manager"
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
        LOGIN_TOKEN = "logisnsgngg-tokensn"
        createLoginToken = sandbox.stub TokenManager, "createLoginToken"
        done = sinon.spy()
        user = new User("user", "pass")
        user.authenticate(done)
        createLoginToken.callArgWith 2, null, LOGIN_TOKEN

        done.should.have.been.calledWithExactly null, user

    it "should not give back the user when authentication failed", ->
        ERROR_TEXT = "WRONG PASSWORD"
        createLoginToken = sandbox.stub TokenManager, "createLoginToken"
        done = sinon.spy()
        user = new User("user", "pass")
        user.authenticate(done)
        createLoginToken.callArgWith 2, new Error ERROR_TEXT, null

        done.should.have.been.calledWithExactly null, false, {message: "Error: #{ERROR_TEXT}"}
