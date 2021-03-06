zmq = require "zmq"
DataConnection = require "../src/scripts/server/data_connection"
VirtDBConnector = require "virtdb-connector"
Const = VirtDBConnector.Const
Proto = (require "virtdb-proto")
lz4 = require "lz4"
QueryIdGenerator = require "../src/scripts/server/query_id_generator"

chai = require "chai"
chai.should()
expect = chai.expect

sinon = require "sinon"
sinonChai = require("sinon-chai")

chai.use sinonChai

QUERY_ADDRESSES = ["query_addr1", "query_addr2"]
COLUMN_ADDRESSES = ["column_addr1", "column_addr2", "column_addr3"]

describe "DataConnection", ->

    sandbox = null
    getNextQueryIdStub = null
    QUERY_ID = null
    logErrorStub = null

    beforeEach =>
        sandbox = sinon.sandbox.create()
        sandbox.stub VirtDBConnector.log, "info"
        sandbox.stub VirtDBConnector.log, "debug"
        sandbox.stub VirtDBConnector.log, "trace"
        sandbox.stub VirtDBConnector.log, "warn"
        logErrorStub = sandbox.stub VirtDBConnector.log, "error"
        getNextQueryIdStub = sandbox.stub(QueryIdGenerator, "getNextQueryId")
        QUERY_ID = "42"
        getNextQueryIdStub.returns QUERY_ID

    afterEach =>
        sandbox.restore()

    it "should create an object and set the addresses", ->
        conn = new DataConnection QUERY_ADDRESSES, COLUMN_ADDRESSES
        conn._queryAddresses.should.be.deep.equal QUERY_ADDRESSES
        conn._columnAddresses.should.be.deep.equal COLUMN_ADDRESSES


    it "should init query socket", ->
        socket = {}
        fakeSocket = sandbox.stub zmq, "socket"
        fakeSocket.returns socket
        socket.connect = sandbox.spy()

        conn = new DataConnection QUERY_ADDRESSES, COLUMN_ADDRESSES
        conn._initQuerySocket()

        fakeSocket.should.have.been.deep.calledWith Const.ZMQ_PUSH
        socket.connect.should.have.been.deep.calledWith QUERY_ADDRESSES[0]
        socket.connect.should.have.been.deep.calledWith QUERY_ADDRESSES[1]

    it "should init column socket", ->
        fakeZmqSocket =
            connect: () ->
            subscribe: () ->
            on: () ->
            setsockopt: () ->

        ON_MSG = () ->

        fakeSocket = sandbox.stub zmq, "socket"
        fakeSocket.returns fakeZmqSocket

        zmqMock = sandbox.mock fakeZmqSocket
        zmqMock.expects("connect").withExactArgs(COLUMN_ADDRESSES[0]).once()
        zmqMock.expects("subscribe").calledWith QUERY_ID
        zmqMock.expects("setsockopt").calledWith zmq.ZMQ_RCVHWM, 100000
        zmqMock.expects("on").calledWithExactly "message", ON_MSG

        conn = new DataConnection QUERY_ADDRESSES, COLUMN_ADDRESSES
        sandbox.stub(conn, "_onColumnMessage", ON_MSG)
        conn._initColumnSocket()

        fakeSocket.should.have.been.deep.calledWith Const.ZMQ_SUB
        zmqMock.verify()

    it "should only close previously connected socket", ->
        socket = zmq.socket "sub"
        (sandbox.stub zmq, "socket").returns socket
        sandbox.stub socket, "connect"
        sandbox.stub socket, "disconnect"
        socket.connect.onFirstCall().throws("Failed to connect!")
        socket.connect.onSecondCall().returns()

        conn = new DataConnection QUERY_ADDRESSES, COLUMN_ADDRESSES
        conn._initColumnSocket(QUERY_ID)
        conn._closeColumnSocket()

        socket.disconnect.withArgs(COLUMN_ADDRESSES[0]).should.have.not.been.called
        socket.disconnect.withArgs(COLUMN_ADDRESSES[1]).should.have.been.calledOnce
        socket.disconnect.withArgs(COLUMN_ADDRESSES[2]).should.have.not.been.called

    it "should close no sockets if all connect attempts failed earlier", ->
        socket = zmq.socket "sub"
        (sandbox.stub zmq, "socket").returns socket
        sandbox.stub socket, "disconnect"
        (sandbox.stub socket, "connect").throws("Failed to connect!")

        conn = new DataConnection QUERY_ADDRESSES, COLUMN_ADDRESSES
        initColumnSocketSpy = sandbox.spy(conn, "_initColumnSocket")
        initColumnSocketSpy.should.throw()
        conn._closeColumnSocket()
        socket.disconnect.should.have.not.been.called

    it "should survive disconnection failure and log an error", ->
        socket = zmq.socket "sub"
        (sandbox.stub zmq, "socket").returns socket
        (sandbox.stub socket, "connect").returns()
        (sandbox.stub socket, "disconnect").throws 'Disconnection failure'

        conn = new DataConnection QUERY_ADDRESSES, COLUMN_ADDRESSES
        conn._initColumnSocket(QUERY_ID)
        conn._closeColumnSocket()

        logErrorStub.should.have.been.calledOnce

    it "should getData when schema is given", ->
        TOKEN = "token"
        ON_DATA = () ->
            console.log "DATA_ARRIVED!!!!"
        TABLE = "table"
        SCHEMA = "schema"
        FIELDS = "fields"
        COUNT = 10
        QUERY_MSG =
            QueryId: QUERY_ID + ""
            Table: TABLE
            Fields: FIELDS
            Limit: COUNT
            Schema: SCHEMA
            UserToken: TOKEN
        SERIALIZED_MSG = "sermsg"

        conn = new DataConnection QUERY_ADDRESSES, COLUMN_ADDRESSES

        initQuerySocketStub = sandbox.stub conn, "_initQuerySocket"
        initColumnSocketStub = sandbox.stub conn, "_initColumnSocket"
        dataSerializeStub = sandbox.stub Proto.data, "serialize"
        dataSerializeStub.returns SERIALIZED_MSG
        sendStub = sandbox.stub()
        conn._querySocket = {send: sendStub, close: sandbox.spy(), disconnect: sandbox.spy()}

        conn.getData TOKEN, SCHEMA, TABLE, FIELDS, COUNT, ON_DATA

        conn._onColumn.should.be.deep.equal ON_DATA
        initQuerySocketStub.should.have.been.calledOnce
        initColumnSocketStub.should.have.been.calledOnce
        dataSerializeStub.should.have.been.calledOnce
        dataSerializeStub.should.have.been.calledWith(QUERY_MSG, "virtdb.interface.pb.Query")
        sendStub.should.have.been.calledOnce
        sendStub.should.have.been.calledWith SERIALIZED_MSG

        conn.close()

    it "should getData when schema is null", ->
        TOKEN = "token"
        ON_DATA = () ->
            console.log "DATA_ARRIVED!!!!"
        TABLE = "table"
        SCHEMA = null
        FIELDS = "fields"
        COUNT = 10
        QUERY_MSG =
            QueryId: QUERY_ID + ""
            Table: TABLE
            Fields: FIELDS
            Limit: COUNT
            Schema: ""
            UserToken: TOKEN
        SERIALIZED_MSG = "sermsg"

        conn = new DataConnection QUERY_ADDRESSES, COLUMN_ADDRESSES

        initQuerySocketStub = sandbox.stub conn, "_initQuerySocket"
        initColumnSocketStub = sandbox.stub conn, "_initColumnSocket"
        dataSerializeStub = sandbox.stub Proto.data, "serialize"
        dataSerializeStub.returns SERIALIZED_MSG
        sendStub = sandbox.stub()
        conn._querySocket = {send: sendStub, close: sandbox.spy(), disconnect: sandbox.spy()}

        conn.getData TOKEN, SCHEMA, TABLE, FIELDS, COUNT, ON_DATA

        conn._onColumn.should.be.deep.equal ON_DATA
        initQuerySocketStub.should.have.been.calledOnce
        initColumnSocketStub.should.have.been.calledOnce
        dataSerializeStub.should.have.been.calledOnce
        dataSerializeStub.should.have.been.calledWithExactly(QUERY_MSG, "virtdb.interface.pb.Query")
        sendStub.should.have.been.calledOnce
        sendStub.should.have.been.calledWith SERIALIZED_MSG
        conn.close()

    it "should getData when schema and token are null", ->
        TOKEN = undefined
        ON_DATA = () ->
            console.log "DATA_ARRIVED!!!!"
        TABLE = "table"
        SCHEMA = null
        FIELDS = "fields"
        COUNT = 10
        QUERY_MSG =
            QueryId: QUERY_ID + ""
            Table: TABLE
            Fields: FIELDS
            Limit: COUNT
            Schema: ""
        SERIALIZED_MSG = "sermsg"

        conn = new DataConnection QUERY_ADDRESSES, COLUMN_ADDRESSES

        initQuerySocketStub = sandbox.stub conn, "_initQuerySocket"
        initColumnSocketStub = sandbox.stub conn, "_initColumnSocket"
        dataSerializeStub = sandbox.stub Proto.data, "serialize"
        dataSerializeStub.returns SERIALIZED_MSG
        sendStub = sandbox.stub()
        conn._querySocket = {send: sendStub, close: sandbox.spy(), disconnect: sandbox.spy()}

        conn.getData TOKEN, SCHEMA, TABLE, FIELDS, COUNT, ON_DATA

        conn._onColumn.should.be.deep.equal ON_DATA
        initQuerySocketStub.should.have.been.calledOnce
        initColumnSocketStub.should.have.been.calledOnce
        dataSerializeStub.should.have.been.calledOnce
        dataSerializeStub.should.have.been.calledWithExactly(QUERY_MSG, "virtdb.interface.pb.Query")
        sendStub.should.have.been.calledOnce
        sendStub.should.have.been.calledWith SERIALIZED_MSG
        conn.close()

    it "should handle column message when it is not compressed", ->
        MSG = "msg"
        CHA = "cha"
        PARSED_MSG =
            CompType: "NOT_LZ4"

        conn = new DataConnection QUERY_ADDRESSES, COLUMN_ADDRESSES
        onColumnStub = sandbox.stub()
        dataParseStub = sandbox.stub Proto.data, "parse"
        dataParseStub.returns PARSED_MSG

        conn._onColumn = onColumnStub
        conn._onColumnMessage CHA, MSG

        dataParseStub.should.have.been.calledOnce
        dataParseStub.should.have.been.calledWithExactly MSG, "virtdb.interface.pb.Column"
        onColumnStub.should.have.been.calledOnce
        onColumnStub.should.have.been.calledWith PARSED_MSG

    it "should handle column message when it is compressed", ->

        CHA = "cha"
        MSG = "msg"

        MSG_CONTENT = "msg_cont"
        input = new Buffer(MSG_CONTENT)
        output = new Buffer(lz4.encodeBound(input.length))
        compSize = lz4.encodeBlock(input, output)
        output = output.slice(0, compSize)

        PARSED_MSG_WITHOUT_DATA =
            CompType: "LZ4_COMPRESSION"
            CompressedData: output
            UncompressedSize: input.length

        PARSED_MSG_WITH_DATA =
            CompType: "LZ4_COMPRESSION"
            CompressedData: output
            UncompressedSize: input.length
            Data: MSG_CONTENT

        conn = new DataConnection QUERY_ADDRESSES, COLUMN_ADDRESSES
        onColumnStub = sandbox.stub()
        dataParseStub = sandbox.stub Proto.data, "parse"
        dataParseStub.returns PARSED_MSG_WITHOUT_DATA
        commonParseStub = sandbox.stub Proto.common, "parse"
        commonParseStub.returns MSG_CONTENT

        conn._onColumn = onColumnStub
        conn._onColumnMessage CHA, MSG

        dataParseStub.should.have.been.calledOnce
        dataParseStub.should.have.been.calledWithExactly MSG, "virtdb.interface.pb.Column"
        commonParseStub.should.have.been.calledOnce
        matcher = sinon.match((buffer) ->
            for i in [0..buffer.length - 1]
                if buffer[i] isnt input[i]
                    return false
            return true
        )
        commonParseStub.should.have.been.calledWith(matcher, "virtdb.interface.pb.ValueType")
        onColumnStub.should.have.been.calledOnce
        onColumnStub.should.have.been.calledWith PARSED_MSG_WITH_DATA
