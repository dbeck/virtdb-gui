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
    socket = null

    beforeEach =>
        sandbox = sinon.sandbox.create()
        sandbox.stub VirtDBConnector.log, "info"
        sandbox.stub VirtDBConnector.log, "debug"
        sandbox.stub VirtDBConnector.log, "trace"
        sandbox.stub VirtDBConnector.log, "warn"
        sandbox.stub VirtDBConnector.log, "error"
        socket = zmq.socket("sub")
        sandbox.stub socket, "connect"

    afterEach =>
        sandbox.restore()

    it "should connect to first address available", ->
        socket.connect.onFirstCall().throws("Failed to connect!")
        socket.connect.onSecondCall().returns()

        ZmqSubConnector.connectToFirstAvailable(socket, COLUMN_ADDRESSES).should.equal COLUMN_ADDRESSES[1]

        socket.connect.withArgs(COLUMN_ADDRESSES[0]).should.have.been.calledOnce
        socket.connect.withArgs(COLUMN_ADDRESSES[1]).should.have.been.calledOnce
        socket.connect.withArgs(COLUMN_ADDRESSES[2]).should.have.not.been.called


    it "should throw exception if all connect attempts fail", ->
        socket.connect.throws("Failed to connect!")
        ( ->
            ZmqSubConnector.connectToFirstAvailable(socket, COLUMN_ADDRESSES).should.equal COLUMN_ADDRESSES[1]
        ).should.throw()
