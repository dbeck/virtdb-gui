VirtDB = require "virtdb-connector"
Const = VirtDB.Const
MetadataHandler = require "../src/scripts/server/meta_data_handler"
CacheHandler = require "../src/scripts/server/cache_handler"
MetaDataProto = (require "virtdb-proto").meta_data

chai = require "chai"
should = chai.should()
expect = chai.expect

sinon = require "sinon"
sinonChai = require("sinon-chai");

chai.use sinonChai

TABLE_LIST_RESPONSE =
    Tables: [
        Name: 'AllstarFull'
        Schema: 'data'
        Fields: []
        Properties: []
        Comments: []
    ,
        Name: 'Appearances'
        Schema: 'data'
        Fields: []
        Properties: []
        Comments: []
    ,
        Name: 'AwardsManagers'
        Schema: 'data'
        Fields: []
        Properties: []
        Comments: []
    ,
        Name: 'table4'
        Schema: 'data'
        Fields: []
        Properties: []
        Comments: []
    ,
        Name: 'table5'
        Schema: 'data'
        Fields: []
        Properties: []
        Comments: []
    ]

TABLE_LIST_RESPONSE_RESULT_FULL =
    from: 0
    to: 4
    count: 5
    results: ['data.AllstarFull', 'data.Appearances', 'data.AwardsManagers', "data.table4", "data.table5"]

TABLE_LIST_RESPONSE_RESULT_PART_24 =
    from: 1
    to: 3
    count: 5
    results: ['data.Appearances', 'data.AwardsManagers', "data.table4"]

TABLE_LIST_RESPONSE_RESULT_PART_TABLE =
    from: 0
    to: 1
    count: 2
    results: ["data.table4", "data.table5"]

TABLE_LIST_RESPONSE_RESULT_PART_DATAA_23 =
    from: 1
    to: 2
    count: 3
    results: ['data.Appearances', 'data.AwardsManagers']

TABLE_LIST_RESPONSE_RESULT_PART_FILTERING =
    from: 0
    to: 1
    count: 2
    results: ["data.table4", "data.table5"]

TABLE_META_RESPONSE =
    Tables: [
        Name: 'AllstarFull'
        Schema: 'data'
        Fields: [
            Name: "Field1"
            Desc:
                Type: "STRING"
            Properties: []
            Comments: []
        ]
        Properties: []
        Comments: []
    ]

TABLE_LIST_REQUEST =
    Name: ".*"
    Schema: ".*"
    WithFields: false

TABLE = "tab"
SCHEMA = "sch"
TABLENAME = "sch.tab"
TABLE_META_REQUEST =
    Name: TABLE
    Schema: SCHEMA
    WithFields: true
PROVIDER = "prov"

describe "MetadataHandler", ->

    sandbox = null

    beforeEach =>
        sandbox = sinon.sandbox.create()
        sandbox.stub VirtDB.log, "info"
        sandbox.stub VirtDB.log, "debug"
        sandbox.stub VirtDB.log, "trace"
        sandbox.stub VirtDB.log, "error"

    afterEach =>
        CacheHandler._reset()
        sandbox.restore()

    describe "getTableList", ->

        it "should send the right request if cache is empty", ->
            SEARCH = ""
            FROM = 0
            TO = 10
            FILTERLIST = []

            requestStub = sandbox.stub VirtDB, "sendRequest"
            cacheHandlerGetStub = sandbox.stub CacheHandler, "get"
            cacheHandlerGetStub.returns null
            handler = new MetadataHandler
            onReadySpy = sandbox.spy()
            handler.getTableList PROVIDER, SEARCH, FROM, TO, FILTERLIST, onReadySpy
            requestStub.should.have.been.calledWith PROVIDER, Const.ENDPOINT_TYPE.META_DATA, (MetaDataProto.serialize TABLE_LIST_REQUEST, "virtdb.interface.pb.MetaDataRequest"), sinon.match.func

        it "should save the received metadata in cache if it wasn't there", ->
            SEARCH = ""
            FROM = 0
            TO = 10
            FILTERLIST = []

            cacheHandlerGetStub = sandbox.stub CacheHandler, "get"
            cacheHandlerGetStub.returns null
            cacheHandlerSetStub = sandbox.stub CacheHandler, "set"
            onReadySpy = sandbox.spy()
            requestStub = sandbox.stub VirtDB, "sendRequest"
            handler = new MetadataHandler
            handler.getTableList PROVIDER, SEARCH, FROM, TO, FILTERLIST, onReadySpy
            requestStub.callArgWith 3, null, (MetaDataProto.serialize TABLE_LIST_RESPONSE, "virtdb.interface.pb.MetaData")
            cacheHandlerSetStub.should.have.been.calledWith sinon.match.string, TABLE_LIST_RESPONSE

        it "should request metadata if it was not in the cache", ->
            SEARCH = ""
            FROM = 0
            TO = 10
            FILTERLIST = []

            requestStub = sandbox.stub VirtDB, "sendRequest"
            cacheHandlerGetStub = sandbox.stub CacheHandler, "get"
            cacheHandlerGetStub.returns null
            handler = new MetadataHandler
            onReadySpy = sandbox.spy()
            handler.getTableList PROVIDER, SEARCH, FROM, TO, FILTERLIST, onReadySpy
            requestStub.should.have.been.called

        it "should not request metadata if it was in the cache", ->
            SEARCH = ""
            FROM = 0
            TO = 10
            FILTERLIST = []

            requestStub = sandbox.stub VirtDB, "sendRequest"
            cacheHandlerGetStub = sandbox.stub CacheHandler, "get"
            cacheHandlerGetStub.returns TABLE_LIST_RESPONSE
            onReadySpy = sandbox.spy()
            handler = new MetadataHandler
            handler.getTableList PROVIDER, SEARCH, FROM, TO, FILTERLIST, onReadySpy
            requestStub.should.not.have.been.called

        it "should return the requested metadata: full table list, no filtering, no search", ->
            SEARCH = ""
            FROM = 0
            TO = 10
            FILTERLIST = []

            cacheHandlerGetStub = sandbox.stub CacheHandler, "get"
            cacheHandlerGetStub.returns null
            onReadySpy = sandbox.spy()
            requestStub = sandbox.stub VirtDB, "sendRequest"
            handler = new MetadataHandler
            handler.getTableList PROVIDER, SEARCH, FROM, TO, FILTERLIST, onReadySpy

            requestStub.callArgWith 3, null, (MetaDataProto.serialize TABLE_LIST_RESPONSE, "virtdb.interface.pb.MetaData")
            onReadySpy.should.have.been.calledWithExactly null, TABLE_LIST_RESPONSE_RESULT_FULL

        it "should return the cached metadata: full table list, no filtering, no search", ->
            SEARCH = ""
            FROM = 0
            TO = 10
            FILTERLIST = []

            cacheHandlerGetStub = sandbox.stub CacheHandler, "get"
            cacheHandlerGetStub.returns TABLE_LIST_RESPONSE
            onReadySpy = sandbox.spy()
            handler = new MetadataHandler
            handler.getTableList PROVIDER, SEARCH, FROM, TO, FILTERLIST, onReadySpy
            onReadySpy.should.have.been.calledWithExactly null, TABLE_LIST_RESPONSE_RESULT_FULL

        it "should return the requested metadata: reduced table list, no filtering, no search", ->
            SEARCH = ""
            FROM = 2
            TO = 4
            FILTERLIST = []

            cacheHandlerGetStub = sandbox.stub CacheHandler, "get"
            cacheHandlerGetStub.returns null
            onReadySpy = sandbox.spy()
            requestStub = sandbox.stub VirtDB, "sendRequest"
            handler = new MetadataHandler
            handler.getTableList PROVIDER, SEARCH, FROM, TO, FILTERLIST, onReadySpy

            requestStub.callArgWith 3, null, (MetaDataProto.serialize TABLE_LIST_RESPONSE, "virtdb.interface.pb.MetaData")
            onReadySpy.should.have.been.calledWithExactly null, TABLE_LIST_RESPONSE_RESULT_PART_24

        it "should give back the cached version if it exists: reduced table list, no filtering, no search", ->
            SEARCH = ""
            FROM = 2
            TO = 4
            FILTERLIST = []

            cacheHandlerGetStub = sandbox.stub CacheHandler, "get"
            cacheHandlerGetStub.returns TABLE_LIST_RESPONSE
            onReadySpy = sandbox.spy()
            handler = new MetadataHandler
            handler.getTableList PROVIDER, SEARCH, FROM, TO, FILTERLIST, onReadySpy
            onReadySpy.should.have.been.calledWithExactly null, TABLE_LIST_RESPONSE_RESULT_PART_24

        it "should return the requested metadata: full table list, no filtering, with search", ->
            SEARCH = "table"
            FROM = 0
            TO = 10
            FILTERLIST = []

            cacheHandlerGetStub = sandbox.stub CacheHandler, "get"
            cacheHandlerGetStub.returns null
            onReadySpy = sandbox.spy()
            requestStub = sandbox.stub VirtDB, "sendRequest"
            handler = new MetadataHandler
            handler.getTableList PROVIDER, SEARCH, FROM, TO, FILTERLIST, onReadySpy

            requestStub.callArgWith 3, null, (MetaDataProto.serialize TABLE_LIST_RESPONSE, "virtdb.interface.pb.MetaData")
            onReadySpy.should.have.been.calledWithExactly null, TABLE_LIST_RESPONSE_RESULT_PART_TABLE

        it "should give back the cached version if it exists: full table list, no filtering, with search", ->
            SEARCH = "table"
            FROM = 0
            TO = 10
            FILTERLIST = []

            cacheHandlerGetStub = sandbox.stub CacheHandler, "get"
            cacheHandlerGetStub.returns TABLE_LIST_RESPONSE
            onReadySpy = sandbox.spy()
            handler = new MetadataHandler
            handler.getTableList PROVIDER, SEARCH, FROM, TO, FILTERLIST, onReadySpy
            onReadySpy.should.have.been.calledWithExactly null, TABLE_LIST_RESPONSE_RESULT_PART_TABLE

        it "should return the requested metadata: reduced table list, no filtering, with search", ->
            SEARCH = "data.A"
            FROM = 2
            TO = 3
            FILTERLIST = []

            cacheHandlerGetStub = sandbox.stub CacheHandler, "get"
            cacheHandlerGetStub.returns null
            onReadySpy = sandbox.spy()
            requestStub = sandbox.stub VirtDB, "sendRequest"
            handler = new MetadataHandler
            handler.getTableList PROVIDER, SEARCH, FROM, TO, FILTERLIST, onReadySpy
            requestStub.callArgWith 3, null, (MetaDataProto.serialize TABLE_LIST_RESPONSE, "virtdb.interface.pb.MetaData")
            onReadySpy.should.have.been.calledWithExactly null, TABLE_LIST_RESPONSE_RESULT_PART_DATAA_23

        it "should return the cached metadata: reduced table list, no filtering, with search", ->
            SEARCH = "data.A"
            FROM = 2
            TO = 3
            FILTERLIST = []

            cacheHandlerGetStub = sandbox.stub CacheHandler, "get"
            cacheHandlerGetStub.returns TABLE_LIST_RESPONSE
            onReadySpy = sandbox.spy()
            handler = new MetadataHandler
            handler.getTableList PROVIDER, SEARCH, FROM, TO, FILTERLIST, onReadySpy
            onReadySpy.should.have.been.calledWithExactly null, TABLE_LIST_RESPONSE_RESULT_PART_DATAA_23

        it "should return the requested metadata: full table list, filtering, no search", ->
            SEARCH = ""
            FROM = 0
            TO = 10
            FILTERLIST = ["data.table4", "data.table5"]

            cacheHandlerGetStub = sandbox.stub CacheHandler, "get"
            cacheHandlerGetStub.returns null
            onReadySpy = sandbox.spy()
            requestStub = sandbox.stub VirtDB, "sendRequest"
            handler = new MetadataHandler
            handler.getTableList PROVIDER, SEARCH, FROM, TO, FILTERLIST, onReadySpy
            requestStub.callArgWith 3, null, (MetaDataProto.serialize TABLE_LIST_RESPONSE, "virtdb.interface.pb.MetaData")
            onReadySpy.should.have.been.calledWithExactly null, TABLE_LIST_RESPONSE_RESULT_PART_FILTERING

        it "should return the cached metadata: full table list, filtering, no search", ->
            SEARCH = ""
            FROM = 0
            TO = 10
            FILTERLIST = ["data.table4", "data.table5"]

            cacheHandlerGetStub = sandbox.stub CacheHandler, "get"
            cacheHandlerGetStub.returns TABLE_LIST_RESPONSE
            onReadySpy = sandbox.spy()
            handler = new MetadataHandler
            handler.getTableList PROVIDER, SEARCH, FROM, TO, FILTERLIST, onReadySpy
            onReadySpy.should.have.been.calledWithExactly null, TABLE_LIST_RESPONSE_RESULT_PART_FILTERING

    describe "getTableMetadata", ->

        it "should send the right request if cache is empty", ->
            (sandbox.stub CacheHandler, "get").returns null
            onReadySpy = sandbox.spy()
            requestStub = sandbox.stub VirtDB, "sendRequest"
            handler = new MetadataHandler
            handler.getTableMetadata PROVIDER, TABLENAME, onReadySpy
            requestStub.should.have.been.calledWith PROVIDER, Const.ENDPOINT_TYPE.META_DATA, (MetaDataProto.serialize TABLE_META_REQUEST, "virtdb.interface.pb.MetaDataRequest"), sinon.match.func

        it "should not request meta data if it is in cache", ->
            TABLE = "table"
            (sandbox.stub CacheHandler, "get").returns TABLE_META_RESPONSE
            onReadySpy = sandbox.spy()
            requestStub = sandbox.stub VirtDB, "sendRequest"
            handler = new MetadataHandler
            handler.getTableMetadata PROVIDER, TABLE, onReadySpy
            requestStub.should.not.have.been.called

        it "should request meta data if it is not in cache", ->
            TABLE = "table"
            (sandbox.stub CacheHandler, "get").returns null
            onReadySpy = sandbox.spy()
            requestStub = sandbox.stub VirtDB, "sendRequest"
            handler = new MetadataHandler
            handler.getTableMetadata PROVIDER, TABLE, onReadySpy
            requestStub.should.have.been.calledOnce

        it "should return the meta data if it was in cache", ->
            TABLE = "table"
            (sandbox.stub CacheHandler, "get").returns TABLE_META_RESPONSE
            onReadySpy = sandbox.spy()
            handler = new MetadataHandler
            handler.getTableMetadata PROVIDER, TABLE, onReadySpy
            onReadySpy.should.have.been.calledWith null, TABLE_META_RESPONSE

        it "should return the requested meta data", ->
            TABLE = "table"
            (sandbox.stub CacheHandler, "get").returns null
            onReadySpy = sandbox.spy()
            requestStub = sandbox.stub VirtDB, "sendRequest"
            handler = new MetadataHandler
            handler.getTableMetadata PROVIDER, TABLE, onReadySpy
            requestStub.callArgWith 3, null, (MetaDataProto.serialize TABLE_META_RESPONSE, "virtdb.interface.pb.MetaData")
            onReadySpy.should.have.been.calledWith null, TABLE_META_RESPONSE

        it "should save meta data to cache when it wasn't there", ->
            TABLE = "table"
            cacheHandlerGetStub = sandbox.stub CacheHandler, "get"
            cacheHandlerGetStub.returns null
            cacheHandlerSetStub = sandbox.stub CacheHandler, "set"
            onReadySpy = sandbox.spy()
            requestStub = sandbox.stub VirtDB, "sendRequest"
            handler = new MetadataHandler
            handler.getTableMetadata PROVIDER, TABLE, onReadySpy
            requestStub.callArgWith 3, null, (MetaDataProto.serialize TABLE_META_RESPONSE, "virtdb.interface.pb.MetaData")
            cacheHandlerSetStub.should.have.been.calledWith sinon.match.string, TABLE_META_RESPONSE

        it "should not save meta data to cache when it doesn't contain any tables", ->
            NO_TABLE_RESPONSE =
                Tables: []
            cacheHandlerGetStub = sandbox.stub CacheHandler, "get"
            cacheHandlerGetStub.returns null
            cacheHandlerSetStub = sandbox.stub CacheHandler, "set"
            onReadySpy = sandbox.spy()
            requestStub = sandbox.stub VirtDB, "sendRequest"
            handler = new MetadataHandler
            handler.getTableMetadata PROVIDER, TABLE, onReadySpy
            requestStub.callArgWith 3, null, (MetaDataProto.serialize NO_TABLE_RESPONSE, "virtdb.interface.pb.MetaData")
            cacheHandlerSetStub.should.not.have.been.called

        it "should not save meta data to cache when the table does not contain any fields", ->
            TABLE = "table"
            NO_FIELDS_RESPONSE =
                Tables: [
                    Name: 'AllstarFull'
                    Schema: 'data'
                    Fields: []
                    Properties: []
                    Comments: []
                ]
            cacheHandlerGetStub = sandbox.stub CacheHandler, "get"
            cacheHandlerGetStub.returns null
            cacheHandlerSetStub = sandbox.stub CacheHandler, "set"
            onReadySpy = sandbox.spy()
            requestStub = sandbox.stub VirtDB, "sendRequest"
            handler = new MetadataHandler
            handler.getTableMetadata PROVIDER, TABLE, onReadySpy
            requestStub.callArgWith 3, null, (MetaDataProto.serialize NO_FIELDS_RESPONSE, "virtdb.interface.pb.MetaData")
            cacheHandlerSetStub.should.not.have.been.called