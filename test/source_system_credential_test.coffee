require("source-map-support").install()
SourceSystemCredential = require "../src/scripts/server/source_system_credential"
Endpoints = require "../src/scripts/server/endpoints"
SocketStub = require "./socket_stub"
zmq     = require 'zmq'
SecurityProto = (require "virtdb-proto").security

chai = require "chai"
should = chai.should()
sinon = require "sinon"
sinonChai = require "sinon-chai"
chai.use sinonChai

SYS_NAME = "NAME"
SYS_TOKEN = "token"
CREDENTIALS =
    NamedValues: [
        Name: "name1"
        Value: "value1"
    ,
        Name: "name2"
        Value: "value2"
    ]
TEMPLATES = [
    Name: "name1"
    Type: "STRING"
,
    Name: "name2"
    Type: "PASSWORD"
]

describe "SourceSystemCredential", ->
    sandbox = null
    socket = null
    connectStub = null

    beforeEach =>
        sandbox = sinon.sandbox.create()
        sandbox.stub Endpoints, "getSourceSystemCredentialAddress", () =>
            return ["ADDR1", "ADDR2"]
        socket = new SocketStub
        connectStub = sandbox.stub zmq, "socket", (type) ->
            type.should.equal 'req'
            return socket
        sandbox.stub (require "virtdb-connector").log, "error"

    afterEach =>
        sandbox.restore()

    describe "setCredential", ->

        it "should send good SourceSystemCredentialRequest", ->
            REQUEST =
                Type: "SET_CREDENTIAL"
                SetCred:
                    SourceSysName: SYS_NAME
                    SourceSysToken: SYS_TOKEN
                    Creds: CREDENTIALS
            SER_REQUEST = SecurityProto.serialize REQUEST, "virtdb.interface.pb.SourceSystemCredentialRequest"

            callback = sinon.spy()
            sourceSystemCredential = new SourceSystemCredential
            sourceSystemCredential.setCredential SYS_NAME, SYS_TOKEN, CREDENTIALS, callback
            socket.send.should.calledWithExactly SER_REQUEST
#            socket.send.should.have.callCount 2

        it "should receive SourceSystemCredentialReply", ->
            REPLY =
                Type: "SET_CREDENTIAL"
            SER_REPLY = SecurityProto.serialize REPLY, "virtdb.interface.pb.SourceSystemCredentialReply"
            callback = sinon.spy()
            sourceSystemCredential = new SourceSystemCredential
            sourceSystemCredential.setCredential SYS_NAME, SYS_TOKEN, CREDENTIALS, callback
            socket.receive SER_REPLY
            callback.should.be.calledWithExactly null, null
#
        it "should receive error when security service replied with error", ->
            ERROR_TEXT = "WRONG PASSWOR"
            REPLY =
                Type: "ERROR_MSG"
                Err:
                    Msg: ERROR_TEXT
            SER_REPLY = SecurityProto.serialize REPLY, "virtdb.interface.pb.SourceSystemCredentialReply"

            callback = sinon.spy()
            sourceSystemCredential = new SourceSystemCredential
            sourceSystemCredential.setCredential SYS_NAME, SYS_TOKEN, CREDENTIALS, callback
            socket.receive SER_REPLY

            callback.should.be.calledWithExactly sinon.match.has("message", ERROR_TEXT), null

        it "should receive error when couldn't communicate with security service", ->
            REQUEST =
                Type: "kiscica"

            callback = sinon.spy()
            sourceSystemCredential = new SourceSystemCredential
            sourceSystemCredential.setCredential SYS_NAME, SYS_TOKEN, CREDENTIALS, callback
            socket.receive REQUEST

            callback.should.be.calledWithExactly sinon.match.defined, null

    describe "getCredential", ->

        it "should send good SourceSystemCredentialRequest", ->
            REQUEST =
                Type: "GET_CREDENTIAL"
                GetCred:
                    SourceSysName: SYS_NAME
                    SourceSysToken: SYS_TOKEN
            SER_REQUEST = SecurityProto.serialize REQUEST, "virtdb.interface.pb.SourceSystemCredentialRequest"

            callback = sinon.spy()
            sourceSystemCredential = new SourceSystemCredential
            sourceSystemCredential.getCredential SYS_NAME, SYS_TOKEN, callback
            socket.send.should.be.calledWithExactly SER_REQUEST

        it "should receive SourceSystemCredentialReply", ->
            REPLY =
                Type: "GET_CREDENTIAL"
                GetCred:
                    Creds: CREDENTIALS
            SER_REPLY = SecurityProto.serialize REPLY, "virtdb.interface.pb.SourceSystemCredentialReply"

            callback = sinon.spy()

            sourceSystemCredential = new SourceSystemCredential
            sourceSystemCredential.getCredential "sysname", "systok", callback
            socket.receive SER_REPLY

            callback.should.be.calledWithExactly null, REPLY.GetCred.Creds

        it "should receive error when security service replied with error", ->
            ERROR_TEXT = "WRONG PASSWOR"
            REPLY =
                Type: "ERROR_MSG"
                Err:
                    Msg: ERROR_TEXT
            SER_REPLY = SecurityProto.serialize REPLY, "virtdb.interface.pb.SourceSystemCredentialReply"

            callback = sinon.spy()
            sourceSystemCredential = new SourceSystemCredential
            sourceSystemCredential.getCredential "sysname", "systok", callback
            socket.receive SER_REPLY

            callback.should.be.calledWithExactly sinon.match.has("message", ERROR_TEXT), null

        it "should receive error when couldn't communicate with security service", ->
            REQUEST =
                Type: "kiscica"

            callback = sinon.spy()
            sourceSystemCredential = new SourceSystemCredential
            sourceSystemCredential.getCredential "sysname", "systok", callback
            socket.receive REQUEST

            callback.should.be.calledWithExactly sinon.match.defined, null

    describe "deleteCredential", ->

        it "should send good SourceSystemCredentialRequest", ->
            REQUEST =
                Type: "DELETE_CREDENTIAL"
                DelCred:
                    SourceSysName: SYS_NAME
                    SourceSysToken: SYS_TOKEN
            SER_REQUEST = SecurityProto.serialize REQUEST, "virtdb.interface.pb.SourceSystemCredentialRequest"
            callback = sinon.spy()
            sourceSystemCredential = new SourceSystemCredential
            sourceSystemCredential.deleteCredential SYS_NAME, SYS_TOKEN, callback
            socket.send.should.be.calledWithExactly SER_REQUEST

        it "should receive SourceSystemCredentialReply", ->
            REPLY =
                Type: "DELETE_CREDENTIAL"
            SER_REPLY = SecurityProto.serialize REPLY, "virtdb.interface.pb.SourceSystemCredentialReply"

            callback = sinon.spy()

            sourceSystemCredential = new SourceSystemCredential
            sourceSystemCredential.deleteCredential "sysname", "systok", callback
            socket.receive SER_REPLY

            callback.should.be.calledWithExactly null, null

        it "should receive error when security service replied with error", ->
            ERROR_TEXT = "WRONG PASSWOR"
            REPLY =
                Type: "ERROR_MSG"
                Err:
                    Msg: ERROR_TEXT
            SER_REPLY = SecurityProto.serialize REPLY, "virtdb.interface.pb.SourceSystemCredentialReply"

            callback = sinon.spy()
            sourceSystemCredential = new SourceSystemCredential
            sourceSystemCredential.deleteCredential "sysname", "systok", callback
            socket.receive SER_REPLY

            callback.should.be.calledWithExactly sinon.match.has("message", ERROR_TEXT), null

        it "should receive error when couldn't communicate with security service", ->
            REQUEST =
                Type: "kiscica"

            callback = sinon.spy()
            sourceSystemCredential = new SourceSystemCredential
            sourceSystemCredential.deleteCredential "sysname", "systok", callback
            socket.receive REQUEST

            callback.should.be.calledWithExactly sinon.match.defined, null

    describe "getTemplate", ->

        it "should send good SourceSystemCredentialRequest", ->
            REQUEST =
                Type: "GET_TEMPLATE"
                GetTmpl:
                    SourceSysName: SYS_NAME
            SER_REQUEST = SecurityProto.serialize REQUEST, "virtdb.interface.pb.SourceSystemCredentialRequest"

            callback = sinon.spy()
            sourceSystemCredential = new SourceSystemCredential
            sourceSystemCredential.getTemplate SYS_NAME, callback
            socket.send.should.be.calledWithExactly SER_REQUEST

        it "should receive SourceSystemCredentialReply", ->
            REPLY =
                Type: "GET_TEMPLATE"
                GetTmpl:
                    Templates: TEMPLATES
            SER_REPLY = SecurityProto.serialize REPLY, "virtdb.interface.pb.SourceSystemCredentialReply"

            callback = sinon.spy()

            sourceSystemCredential = new SourceSystemCredential
            sourceSystemCredential.getTemplate SYS_NAME, callback
            socket.receive SER_REPLY

            callback.should.be.calledWithExactly null, REPLY.GetTmpl.Templates

        it "should receive error when security service replied with error", ->
            ERROR_TEXT = "WRONG PASSWOR"
            REPLY =
                Type: "ERROR_MSG"
                Err:
                    Msg: ERROR_TEXT
            SER_REPLY = SecurityProto.serialize REPLY, "virtdb.interface.pb.SourceSystemCredentialReply"

            callback = sinon.spy()
            sourceSystemCredential = new SourceSystemCredential
            sourceSystemCredential.getTemplate SYS_NAME, callback
            socket.receive SER_REPLY

            callback.should.be.calledWithExactly sinon.match.has("message", ERROR_TEXT), null

        it "should receive error when couldn't communicate with security service", ->
            REQUEST =
                Type: "kiscica"

            callback = sinon.spy()
            sourceSystemCredential = new SourceSystemCredential
            sourceSystemCredential.getTemplate SYS_NAME, callback
            socket.receive REQUEST

            callback.should.be.calledWithExactly sinon.match.defined, null

    describe "setTemplate", ->

        it "should send good SourceSystemCredentialRequest", ->
            REQUEST =
                Type: "SET_TEMPLATE"
                SetTmpl:
                    SourceSysName: SYS_NAME
                    Templates: TEMPLATES
            SER_REQUEST = SecurityProto.serialize REQUEST, "virtdb.interface.pb.SourceSystemCredentialRequest"

            callback = sinon.spy()
            sourceSystemCredential = new SourceSystemCredential
            sourceSystemCredential.setTemplate SYS_NAME, TEMPLATES, callback
            socket.send.should.be.calledWithExactly SER_REQUEST

        it "should receive SourceSystemCredentialReply", ->
            REPLY =
                Type: "SET_TEMPLATE"
            SER_REPLY = SecurityProto.serialize REPLY, "virtdb.interface.pb.SourceSystemCredentialReply"

            callback = sinon.spy()

            sourceSystemCredential = new SourceSystemCredential
            sourceSystemCredential.setTemplate SYS_NAME, TEMPLATES, callback
            socket.receive SER_REPLY

            callback.should.be.calledWithExactly null, null

        it "should receive error when security service replied with error", ->
            ERROR_TEXT = "WRONG PASSWOR"
            REPLY =
                Type: "ERROR_MSG"
                Err:
                    Msg: ERROR_TEXT
            SER_REPLY = SecurityProto.serialize REPLY, "virtdb.interface.pb.SourceSystemCredentialReply"

            callback = sinon.spy()
            sourceSystemCredential = new SourceSystemCredential
            sourceSystemCredential.setTemplate SYS_NAME, TEMPLATES, callback
            socket.receive SER_REPLY

            callback.should.be.calledWithExactly sinon.match.has("message", ERROR_TEXT), null

        it "should receive error when couldn't communicate with security service", ->
            REQUEST =
                Type: "kiscica"

            callback = sinon.spy()
            sourceSystemCredential = new SourceSystemCredential
            sourceSystemCredential.setTemplate SYS_NAME, TEMPLATES, callback
            socket.receive REQUEST

            callback.should.be.calledWithExactly sinon.match.defined, null
