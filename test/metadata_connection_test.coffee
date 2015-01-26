zmq = require "zmq"
MetadataConnection = require "../src/scripts/server/metadata_connection"
VirtDBConnector = require "virtdb-connector"
Const = VirtDBConnector.Constants
Proto = (require "virtdb-proto")

chai = require "chai"
chai.should()
expect = chai.expect

sinon = require "sinon"
sinonChai = require("sinon-chai");

chai.use sinonChai

META_ADDRESS = "meta_addr"

describe "MetadataConnection", ->

    sandbox = null

    beforeEach =>
        sandbox = sinon.sandbox.create()
        sandbox.stub VirtDBConnector.log, "info"
        sandbox.stub VirtDBConnector.log, "debug"
        sandbox.stub VirtDBConnector.log, "trace"
        sandbox.stub VirtDBConnector.log, "error"

    afterEach =>
        sandbox.restore()

    it "should create an object and set the addresses", ->
        conn = new MetadataConnection META_ADDRESS
        conn._metadataAddress.should.be.deep.equal META_ADDRESS

    it "should init meta socket", ->
        fakeZmqSocket =
            connect: () ->
            on: () ->

        ON_MSG = () ->
            console.log "METADATA!!!!"

        fakeSocket = sandbox.stub zmq, "socket"
        fakeSocket.returns fakeZmqSocket

        zmqMock = sandbox.mock fakeZmqSocket
        zmqMock.expects("connect").calledWith Const.COLUMN_ADDRESS
        zmqMock.expects("on").calledWithExactly "message", ON_MSG

        conn = new MetadataConnection META_ADDRESS
        sandbox.stub(conn, "_onMetadataMessage", ON_MSG)
        conn._initMetadataSocket()

        fakeSocket.should.have.been.deep.calledWith Const.ZMQ_REQ
        zmqMock.verify()

    it "should handle metadata message", ->
        MSG = "msg"
        PARSED_MSG = "parsed_msg"

        metadataParseStub = sandbox.stub Proto.meta_data, "parse"
        metadataParseStub.returns PARSED_MSG

        conn = new MetadataConnection META_ADDRESS
        conn._onMetadata = sandbox.spy()

        conn._onMetadataMessage MSG

        metadataParseStub.should.have.been.calledOnce
        metadataParseStub.should.have.been.calledWithExactly MSG, "virtdb.interface.pb.MetaData"
        conn._onMetadata.should.have.been.calledOnce
        conn._onMetadata.should.have.been.calledWith PARSED_MSG

    it "should send the right metadata request message", ->

        REQ = "request"
        SER_REQ = "ser_req"
        ON_META = () ->
            console.log "META!!!!!"

        conn = new MetadataConnection META_ADDRESS

        initSocketStub = sandbox.stub conn, "_initMetadataSocket"
        metadataProtoStub = sandbox.stub Proto.meta_data, "serialize"
        metadataProtoStub.returns SER_REQ
        sendStub = sandbox.stub()
        conn._metadataSocket = {send: sendStub}

        conn.getMetadata REQ, ON_META

        conn._onMetadata.should.be.deep.equal ON_META
        metadataProtoStub.should.have.been.calledOnce
        metadataProtoStub.should.have.been.calledWithExactly REQ, "virtdb.interface.pb.MetaDataRequest"
        sendStub.should.have.been.calledOnce
        sendStub.should.have.been.calledWith SER_REQ
