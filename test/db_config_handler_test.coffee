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
ACTION = 'CREATE'

USER_NAME = "USER"
PASSWORD  = "2423ldhlkvs"
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
    Type: 'ADD_TABLE'
    AddTable:
        Provider: PROVIDER
        Table: TABLE_METADATA1

DB_CONFIG_DELETE_REQUEST_WITH_USER =
    Type: 'DELETE_TABLE'
    DeleteTable:
        Provider: PROVIDER
        Table: TABLE_METADATA1
        UserName: USER_NAME

DB_CONFIG_DELETE_REQUEST =
    Type: 'DELETE_TABLE'
    DeleteTable:
        Provider: PROVIDER
        Table: TABLE_METADATA1

DB_CONFIG_REQUEST =
    Type: 'QUERY_TABLES'
    QueryTables:
        Provider: PROVIDER

DB_CONFIG_REPLY1 =
    Type: 'QUERY_TABLES'
    QueryTables:
        Tables: [TABLE_METADATA1]
DB_CONFIG_REPLY2 =
    Type: 'QUERY_TABLES'
    QueryTables:
        Tables: [TABLE_METADATA1, TABLE_METADATA2, TABLE_METADATA3]

DB_CONFIG_ADD_REPLY_NO_ERROR =
    Type: 'ADD_TABLE'
ERROR_TEXT = "Some very bad thing happened!"
ERROR = new Error ERROR_TEXT
DB_CONFIG_ADD_REPLY_ERROR =
    Type: 'ADD_TABLE'
    Err:
        Msg: ERROR_TEXT

DB_CONFIG_DELETE_REPLY_NO_ERROR =
    Type: 'DELETE_TABLE'
DB_CONFIG_DELETE_REPLY_ERROR =
    Type: 'DELETE_TABLE'
    Err:
        Msg: ERROR_TEXT

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
            DBConfig.getTables PROVIDER, null, cb
            requestStub.should.have.been.calledWithExactly DB_CONFIG, Const.ENDPOINT_TYPE.DB_CONFIG, (DBConfigProto.serialize DB_CONFIG_REQUEST, "virtdb.interface.pb.DBConfigRequest"), sinon.match.func

        it "should cache the received data", ->
             cacheGetStub.returns null
             requestStub.yields null, (DBConfigProto.serialize DB_CONFIG_REPLY1, "virtdb.interface.pb.DBConfigReply")
             DBConfig.getTables PROVIDER, null, cb
             cacheSetStub.should.have.been.calledWithExactly sinon.match.string, ["#{TABLE_SCHEMA1}.#{TABLE_NAME1}"]

        it "should return the cached data if it is available", ->
            result = ["#{TABLE_SCHEMA1}.#{TABLE_NAME1}"]
            cacheGetStub.returns result
            DBConfig.getTables PROVIDER, null, cb
            requestStub.should.not.have.been.called
            cb.should.have.been.calledWithExactly result

        it "should return the received data if it is not available from cache: 1 table", ->
            cacheGetStub.returns null
            requestStub.yields null, (DBConfigProto.serialize DB_CONFIG_REPLY1, "virtdb.interface.pb.DBConfigReply")
            DBConfig.getTables PROVIDER, null, cb
            requestStub.should.have.been.calledOnce
            cb.should.have.been.calledWithExactly ["#{TABLE_SCHEMA1}.#{TABLE_NAME1}"]

        it "should return the received data if it is not available from cache: one table: 3 table", ->
            cacheGetStub.returns null
            requestStub.yields null, (DBConfigProto.serialize DB_CONFIG_REPLY2, "virtdb.interface.pb.DBConfigReply")
            DBConfig.getTables PROVIDER, null, cb
            cb.should.have.been.calledWithExactly ["#{TABLE_SCHEMA1}.#{TABLE_NAME1}","#{TABLE_SCHEMA2}.#{TABLE_NAME2}","#{TABLE_SCHEMA3}.#{TABLE_NAME3}",]

    describe "addTable", ->

        it "should send good request", ->
            DBConfig.addTable PROVIDER, METADATA, null, cb
            requestStub.should.have.been.calledWithExactly DB_CONFIG, Const.ENDPOINT_TYPE.DB_CONFIG, (DBConfigProto.serialize DB_CONFIG_ADD_REQUEST, "virtdb.interface.pb.DBConfigRequest"), sinon.match.func

        it "should response null when no error", ->
            requestStub.yields null, (DBConfigProto.serialize DB_CONFIG_ADD_REPLY_NO_ERROR, "virtdb.interface.pb.DBConfigReply")
            DBConfig.addTable PROVIDER, METADATA, null, cb
            cb.should.have.been.calledWithExactly null

        it "should response the error when it occurs", ->
            requestStub.yields null, (DBConfigProto.serialize DB_CONFIG_ADD_REPLY_ERROR, "virtdb.interface.pb.DBConfigReply")
            DBConfig.addTable PROVIDER, METADATA, null, cb
            cb.should.have.been.calledWith ERROR

        it "should empty cache when db config changed", ->
            keyToDelete = "db_config_tables_" + PROVIDER
            requestStub.yields null, (DBConfigProto.serialize DB_CONFIG_ADD_REPLY_NO_ERROR, "virtdb.interface.pb.DBConfigReply")
            cacheListKeyStub.returns [keyToDelete, "db_config_tables_prov2", "db_es_prov3"]
            DBConfig.addTable PROVIDER, METADATA, null, cb
            cacheDelStub.should.have.been.calledWithExactly keyToDelete

    describe "deleteTable", ->

        it "should send good request", ->
            DBConfig.deleteTable PROVIDER, METADATA, null, cb
            requestStub.should.have.been.calledWithExactly DB_CONFIG, Const.ENDPOINT_TYPE.DB_CONFIG, (DBConfigProto.serialize DB_CONFIG_DELETE_REQUEST, "virtdb.interface.pb.DBConfigRequest"), sinon.match.func

        it "should send good request is username is given", ->
            DBConfig.deleteTable PROVIDER, METADATA, USER_NAME, cb
            serializedMessage = DBConfigProto.serialize DB_CONFIG_DELETE_REQUEST_WITH_USER, "virtdb.interface.pb.DBConfigRequest"
            requestStub.should.have.been.calledWithExactly DB_CONFIG, Const.ENDPOINT_TYPE.DB_CONFIG, serializedMessage, sinon.match.func

        it "should response null when no error", ->
            requestStub.yields null, (DBConfigProto.serialize DB_CONFIG_DELETE_REPLY_NO_ERROR, "virtdb.interface.pb.DBConfigReply")
            DBConfig.deleteTable PROVIDER, METADATA, null, cb
            cb.should.have.been.calledWithExactly null

        it "should response the error when it occurs", ->
            requestStub.yields null, (DBConfigProto.serialize DB_CONFIG_DELETE_REPLY_ERROR, "virtdb.interface.pb.DBConfigReply")
            DBConfig.deleteTable PROVIDER, METADATA, null, cb
            cb.should.have.been.calledWith ERROR

        it "should empty cache when db config changed", ->
            keyToDelete = "db_config_tables_" + PROVIDER
            requestStub.yields null, (DBConfigProto.serialize DB_CONFIG_DELETE_REPLY_NO_ERROR, "virtdb.interface.pb.DBConfigReply")
            cacheListKeyStub.returns [keyToDelete, "db_config_tables_prov2", "db_es_prov3"]
            DBConfig.deleteTable PROVIDER, METADATA, null, cb
            cacheDelStub.should.have.been.calledWithExactly keyToDelete

    describe "createUser", ->

        it "should send good request when password is missing", ->
            message =
                Type: "CREATE_USER"
                CreateUser:
                    UserName: USER_NAME
            DBConfig.createUser USER_NAME
            requestStub.should.have.been.calledWithExactly DB_CONFIG, Const.ENDPOINT_TYPE.DB_CONFIG, (DBConfigProto.serialize message, "virtdb.interface.pb.DBConfigRequest"), sinon.match.func

        it "should send good request when password is missing", ->
            message =
                Type: "CREATE_USER"
                CreateUser:
                    UserName: USER_NAME
                    Password: PASSWORD
            DBConfig.createUser USER_NAME, PASSWORD
            requestStub.should.have.been.calledWithExactly DB_CONFIG, Const.ENDPOINT_TYPE.DB_CONFIG, (DBConfigProto.serialize message, "virtdb.interface.pb.DBConfigRequest"), sinon.match.func

    describe "updateUser", ->

        it "should send good request", ->
            message =
                Type: "UPDATE_USER"
                UpdateUser:
                    UserName: USER_NAME
                    Password: PASSWORD
            DBConfig.updateUser USER_NAME, PASSWORD
            requestStub.should.have.been.calledWithExactly DB_CONFIG, Const.ENDPOINT_TYPE.DB_CONFIG, (DBConfigProto.serialize message, "virtdb.interface.pb.DBConfigRequest"), sinon.match.func

    describe "deleteUser", ->

        it "should send good request", ->
            message =
                Type: "DELETE_USER"
                DeleteUser:
                    UserName: USER_NAME
            DBConfig.deleteUser USER_NAME
            requestStub.should.have.been.calledWithExactly DB_CONFIG, Const.ENDPOINT_TYPE.DB_CONFIG, (DBConfigProto.serialize message, "virtdb.interface.pb.DBConfigRequest"), sinon.match.func

    describe "listUsers", ->

        it "should send good request", ->
            message =
                Type: "LIST_USERS"
            callback = sinon.spy()
            DBConfig.listUsers callback
            requestStub.should.have.been.calledWithExactly DB_CONFIG, Const.ENDPOINT_TYPE.DB_CONFIG, (DBConfigProto.serialize message, "virtdb.interface.pb.DBConfigRequest"), sinon.match.func

        it "should give back the user list", ->
            users =
                Name: [
                    "Bela"
                ,
                    "Joska"
                ,
                    "Pista"
            ]
            reply =
                Type: "LIST_USERS"
                Users: users
            callback = sinon.spy()
            requestStub.yields null, (DBConfigProto.serialize reply, "virtdb.interface.pb.DBConfigReply")
            DBConfig.listUsers callback
            callback.should.have.been.calledWithExactly null, users.Name

        it "should give back null when error happened", ->
            errorText = "SOME VERY BAD THING HAPPENED"
            error = new Error errorText
            reply =
                Type: "LIST_USERS"
                Err:
                    Msg: errorText
            callback = sinon.spy()
            requestStub.yields null, (DBConfigProto.serialize reply, "virtdb.interface.pb.DBConfigReply")
            DBConfig.listUsers callback
            callback.should.have.been.calledWithExactly error, null

    it "should empty cache when db config changed", ->
        cacheListKeyStub.returns ["db_config_tables_prov1", "db_config_tables_prov2", "db_es_prov3"]
        DBConfig.setDBConfig "valami_mas"
        cacheDelStub.should.have.been.calledTwice
        cacheDelStub.should.have.been.calledWith "db_config_tables_prov1"
        cacheDelStub.should.have.been.calledWith "db_config_tables_prov2"

