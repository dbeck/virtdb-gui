VirtDB = require "virtdb-connector"
Const = VirtDB.Const
CacheHandler = require "../src/scripts/server/cache_handler"
DBConfig = require "../src/scripts/server/db_config_connector"
DBConfigProto = (require "virtdb-proto").db_config
Cache = require "../src/scripts/server/cache_handler"

chai = require "chai"
should = chai.should()
expect = chai.expect

sinon = require "sinon"
sinonChai = require("sinon-chai");

chai.use sinonChai

PROVIDER = "prov"
ACTION = "CREATE"

TABLE_NAME1 = 'AllstarFull1'
TABLE_NAME2 = 'AllstarFull2'
TABLE_NAME3 = 'AllstarFull3'
TABLE_SCHEMA1 = 'data1'
TABLE_SCHEMA2 = 'data2'
TABLE_SCHEMA3 = 'data3'
TABLE_METADATA1 =
    Name: TABLE_NAME1
    Schema: TABLE_SCHEMA1
    Fields: [
        Name: "Field3"
        Desc:
            Type: "STRING"
        Properties: []
        Comments: []
    ]
TABLE_METADATA2 =
    Name: TABLE_NAME2
    Schema: TABLE_SCHEMA2
    Fields: [
        Name: "Field2"
        Desc:
            Type: "STRING"
        Properties: []
        Comments: []
    ]
TABLE_METADATA3 =
    Name: TABLE_NAME3
    Schema: TABLE_SCHEMA3
    Fields: [
        Name: "Field3"
        Desc:
            Type: "STRING"
        Properties: []
        Comments: []
    ]
METADATA =
    Tables: [TABLE_METADATA1]
    Properties: []
    Comments: []

DB_CONFIG_ADD_REQUEST =
    Name: PROVIDER
    Action: ACTION
    Table: TABLE_METADATA1

DB_CONFIG_QUERY_REQUEST =
    Name: PROVIDER

DB_CONFIG_QUERY_REPLY1 =
    Tables: [TABLE_METADATA1]
DB_CONFIG_QUERY_REPLY2 =
    Tables: [TABLE_METADATA1, TABLE_METADATA2, TABLE_METADATA3]

DB_CONFIG_REPLY_NO_ERROR = {}
ERROR_TEXT = "Some very bad thing happened!"
DB_CONFIG_REPLY_ERROR =
    Error: ERROR_TEXT

DB_CONFIG = "db-config"

describe "DBConfig", ->

    sandbox = null
    cb = null
    cacheSetStub = null
    cacheGetStub = null
    cacheDelStub = null
    cacheListKeyStub = null
    requestStub = null

    beforeEach =>
        sandbox = sinon.sandbox.create()
        sandbox.stub VirtDB.log, "info"
        sandbox.stub VirtDB.log, "debug"
        sandbox.stub VirtDB.log, "trace"
        sandbox.stub VirtDB.log, "error"
        cb = sandbox.spy()
        DBConfig.setDBConfig DB_CONFIG
        cacheSetStub = sandbox.stub Cache, "set"
        cacheGetStub = sandbox.stub Cache, "get"
        cacheDelStub = sandbox.stub Cache, "delete"
        cacheListKeyStub = sandbox.stub Cache, "listKeys"
        requestStub = sandbox.stub VirtDB, "sendRequest"

    afterEach =>
        sandbox.restore()

    describe "getTables", ->

        it "should send good request", ->
            cacheGetStub.returns null
            DBConfig.getTables PROVIDER, cb
            requestStub.should.have.been.calledWithExactly DB_CONFIG, Const.ENDPOINT_TYPE.DB_CONFIG_QUERY, (DBConfigProto.serialize DB_CONFIG_QUERY_REQUEST, "virtdb.interface.pb.DbConfigQuery"), sinon.match.func

        it "should cache the received data", ->
             cacheGetStub.returns null
             requestStub.yields null, (DBConfigProto.serialize DB_CONFIG_QUERY_REPLY1, "virtdb.interface.pb.DbConfigReply")
             DBConfig.getTables PROVIDER, cb
             cacheSetStub.should.have.been.calledWithExactly sinon.match.string, ["#{TABLE_SCHEMA1}.#{TABLE_NAME1}"]

        it "should return the cached data if it is available", ->
            result = ["#{TABLE_SCHEMA1}.#{TABLE_NAME1}"]
            cacheGetStub.returns result
            DBConfig.getTables PROVIDER, cb
            requestStub.should.not.have.been.called
            cb.should.have.been.calledWithExactly result

        it "should return the received data if it is not available from cache: 1 table", ->
            cacheGetStub.returns null
            requestStub.yields null, (DBConfigProto.serialize DB_CONFIG_QUERY_REPLY1, "virtdb.interface.pb.DbConfigReply")
            DBConfig.getTables PROVIDER, cb
            requestStub.should.have.been.calledOnce
            cb.should.have.been.calledWithExactly ["#{TABLE_SCHEMA1}.#{TABLE_NAME1}"]

        it "should return the received data if it is not available from cache: one table: 3 table", ->
            cacheGetStub.returns null
            requestStub.yields null, (DBConfigProto.serialize DB_CONFIG_QUERY_REPLY2, "virtdb.interface.pb.DbConfigReply")
            DBConfig.getTables PROVIDER, cb
            cb.should.have.been.calledWithExactly ["#{TABLE_SCHEMA1}.#{TABLE_NAME1}","#{TABLE_SCHEMA2}.#{TABLE_NAME2}","#{TABLE_SCHEMA3}.#{TABLE_NAME3}",]

    describe "addTable", ->

        it "should send good request", ->
            DBConfig.addTable PROVIDER, METADATA, ACTION, cb
            requestStub.should.have.been.calledWithExactly DB_CONFIG, Const.ENDPOINT_TYPE.DB_CONFIG, (DBConfigProto.serialize DB_CONFIG_ADD_REQUEST, "virtdb.interface.pb.ServerConfig"), sinon.match.func

        it "should response null when no error", ->
            requestStub.yields null, (DBConfigProto.serialize DB_CONFIG_REPLY_NO_ERROR, "virtdb.interface.pb.ServerConfigReply")
            DBConfig.addTable PROVIDER, METADATA, ACTION, cb
            cb.should.have.been.calledWithExactly null

        it "should response the error when it occurs", ->
            requestStub.yields null, (DBConfigProto.serialize DB_CONFIG_REPLY_ERROR, "virtdb.interface.pb.ServerConfigReply")
            DBConfig.addTable PROVIDER, METADATA, ACTION, cb
            cb.should.have.been.calledWith DB_CONFIG_REPLY_ERROR

        it "should empty cache when db config changed", ->
            keyToDelete = "db_config_tables_" + PROVIDER
            requestStub.yields null, (DBConfigProto.serialize DB_CONFIG_REPLY_NO_ERROR, "virtdb.interface.pb.ServerConfigReply")
            cacheListKeyStub.returns [keyToDelete, "db_config_tables_prov2", "db_es_prov3"]
            DBConfig.addTable PROVIDER, METADATA, ACTION, cb
            cacheDelStub.should.have.been.calledWithExactly keyToDelete

    it "should empty cache when db config changed", ->
        cacheListKeyStub.returns ["db_config_tables_prov1", "db_config_tables_prov2", "db_es_prov3"]
        DBConfig.setDBConfig "valami_mas"
        cacheDelStub.should.have.been.calledTwice
        cacheDelStub.should.have.been.calledWith "db_config_tables_prov1"
        cacheDelStub.should.have.been.calledWith "db_config_tables_prov2"

