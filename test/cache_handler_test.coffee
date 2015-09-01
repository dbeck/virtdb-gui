require("source-map-support").install()
NodeCache = require "node-cache"
Config = require "../src/scripts/server/config"
Cache = require "../src/scripts/server/cache_handler"
VirtDBConnector = require "virtdb-connector"
log = VirtDBConnector.log

chai = require "chai"
expect = chai.expect
should = chai.should()
sinon = require "sinon"
sinonChai = require("sinon-chai");
chai.use sinonChai

describe "Cache", ->

    sandbox = null
    clock = null

    beforeEach =>
        clock = sinon.useFakeTimers()
        sandbox = sinon.sandbox.create()
        sandbox.stub VirtDBConnector.log, "info"
        sandbox.stub VirtDBConnector.log, "debug"
        sandbox.stub VirtDBConnector.log, "trace"
        sandbox.stub VirtDBConnector.log, "error"
        clock.tick 100
        Cache._onNewCacheTTL 1

    afterEach =>
        Cache.reset()
        sandbox.restore()
        clock.restore()


    it "should store the data and give it back if we get it before ttl", ->

        DATA = "data"
        KEY = "key"
        OBJ = {}
        OBJ[KEY] = DATA

        Cache.set KEY, DATA
        clock.tick 800
        result = Cache.get KEY
        result.should.be.deep.equal DATA

    it "should store an array and give it back if we get it before ttl", ->

        DATA = {
            Tables: [
                Name: 'BSEG'
                Comments: []
                Properties: []
                Fields: [
                    Name: "MANDT"
                    Desc:
                        Type: "INT32"
                    Comments: [
                        Text: 'Client'
                        Language: 'EN'
                    ]
                    Properties: [
                        Key: 'fieldname'
                        Children: []
                        Value:
                            Type: 'STRING'
                            StringValue: 'MANDT'
                    ,
                        Key: 'position'
                        Children: []
                        Value:
                            Type: 'STRING'
                            Value: '0'
                    ]
                ]
            ]
        }
        KEY = "sap_{\"Name\":\"BSEG\",\"WithFields\":true}"
        OBJ = {}
        OBJ[KEY] = DATA

        Cache.set KEY, DATA
        clock.tick 200
        result = Cache.get KEY
        result.should.deep.equal DATA

    it "should store large data and give it back if we get it before ttl", ->

        DATA =
            Tables: []

        for i in [0..4]
            table = {}
            table.Name = "table #{i}"
            table.Fields = []
            for fieldIndex in [0..400]
                field = {}
                field.Name = "field#{table.Name}#{fieldIndex}"
                table.Fields.push field
            DATA.Tables.push table

        KEY = "key"
        OBJ = {}
        OBJ[KEY] = DATA

        Cache.set KEY, DATA
        clock.tick 200
        result = Cache.get KEY
        result.should.deep.equal DATA

    it "should return null if data requested after ttl", ->

        DATA = "data"
        KEY = "key"

        Cache.set KEY, DATA
        clock.tick 1500
        result = Cache.get KEY
        should.not.exist result

    it "should use new ttl value", ->
        Cache._onNewCacheTTL 3
        getSpy = sandbox.spy Cache, "get"
        Cache.set "key", "value"
        clock.tick 2500
        value = Cache.get "key"
        value.should.be.equal "value"

    it "should register for the parameter changes to the config", ->
        addCfgListStub = sandbox.stub Config, "addConfigListener"
        Cache.init()
        addCfgListStub.should.have.been.calledWith Config.CACHE_TTL

    it "should call the key expiration listeners if there are some", ->
        expListener1 = sandbox.spy()
        expListener2 = sandbox.spy()
        KEY1 = "KEY1"
        clock.tick 200

        Cache.addKeyExpirationListener KEY1, expListener1
        Cache.addKeyExpirationListener KEY1, expListener2
        Cache.set KEY1, "value"
        clock.tick 2000

        expListener1.should.have.been.calledOnce
        expListener2.should.have.been.calledOnce

    it "should not crash when there are no any listener to key and it was expired", ->
        clock.tick 200
        Cache.set "key", "value"
        clock.tick 2000

    it "should delete key expiration listeners after they have been called", ->
        expListener1 = sandbox.spy()
        expListener2 = sandbox.spy()
        KEY1 = "KEY1"
        Cache.addKeyExpirationListener KEY1, expListener1
        Cache.addKeyExpirationListener KEY1, expListener2
        Cache.set KEY1, "value"
        clock.tick 2000
        Cache.set KEY1, "value"
        clock.tick 2000
        expListener1.should.have.been.calledOnce
        expListener2.should.have.been.calledOnce


    it "should list the stored keys", ->

        DATA = "data"
        KEY1 = "key1"
        KEY2 = "key2"

        Cache.set KEY1, DATA
        Cache.set KEY2, DATA
        clock.tick 300
        keys = Cache.listKeys()
        keys.should.be.deep.equal [KEY1, KEY2]

    it "should delete the entry", ->

        DATA = "data"
        KEY = "key"

        Cache.set KEY, DATA
        Cache.delete KEY
        result = Cache.get KEY
        should.not.exist result

    it "should be able to store dbconfig and metadata keys and parse them while iterating over", ->
        DATA_META = "meta"
        DATA_DB_CONFIG = "dbconf"
        KEY_META = Cache.generateCacheKeyForMetadata "oracle-cache", { some: "object" }
        Cache.set KEY_META, DATA_META
        KEY_DB_CONFIG = Cache.generateDBConfigCacheKey "sap-provider"
        Cache.set KEY_DB_CONFIG, DATA_DB_CONFIG
        for key in Cache.listKeys()
            Cache.parseCacheKeyOfMetadata key

