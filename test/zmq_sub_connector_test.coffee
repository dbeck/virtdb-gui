zmq = require "zmq"
VirtDBConnector = require "virtdb-connector"
ZmqSubConnector = require "../src/scripts/server/zmq_sub_connector"

chai = require "chai"
chai.should()
expect = chai.expect

sinon = require "sinon"
sinonChai = require("sinon-chai");

chai.use sinonChai

QUERY_ADDRESSES = ["query_addr1", "query_addr2"]
COLUMN_ADDRESSES = ["column_addr1", "column_addr2", "column_addr3"]

describe "ZmqSubConnector", ->

    sandbox = null
    fakeZmqSocket = null

    beforeEach =>
        sandbox = sinon.sandbox.create()
        sandbox.stub VirtDBConnector.log, "info"
        sandbox.stub VirtDBConnector.log, "debug"
        sandbox.stub VirtDBConnector.log, "trace"
        sandbox.stub VirtDBConnector.log, "warn"
        sandbox.stub VirtDBConnector.log, "error"
        fakeZmqSocket = sinon.createStubInstance zmq.Socket

    afterEach =>
        sandbox.restore()

    it "should init column socket on first available address", ->
        fakeZmqSocket.connect.onFirstCall().throws("Failed to connect!")
        fakeZmqSocket.connect.onSecondCall().returns()

        ZmqSubConnector.connectToFirstAvailable(fakeZmqSocket, COLUMN_ADDRESSES).should.equal COLUMN_ADDRESSES[1]

        fakeZmqSocket.connect.withArgs(COLUMN_ADDRESSES[0]).should.have.been.calledOnce
        fakeZmqSocket.connect.withArgs(COLUMN_ADDRESSES[1]).should.have.been.calledOnce
        fakeZmqSocket.connect.withArgs(COLUMN_ADDRESSES[2]).should.have.not.been.called


    it "should close no sockets if all connect attempts failed earlier", ->
        fakeZmqSocket = sinon.createStubInstance zmq.Socket
        fakeZmqSocket.connect.throws("Failed to connect!")

        ( ->
            ZmqSubConnector.connectToFirstAvailable(fakeZmqSocket, COLUMN_ADDRESSES).should.equal COLUMN_ADDRESSES[1]
        ).should.throw()
