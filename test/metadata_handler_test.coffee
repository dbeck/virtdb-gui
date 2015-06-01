VirtDBConnector = require "virtdb-connector"
MetadataHandler = require "../src/scripts/server/meta_data_handler"
MetadataConnection = require "../src/scripts/server/metadata_connection"
CacheHandler = require "../src/scripts/server/cache_handler"
Config = require "../src/scripts/server/config"
Endpoints = require "../src/scripts/server/endpoints"

chai = require "chai"
should = chai.should()
expect = chai.expect

sinon = require "sinon"
sinonChai = require("sinon-chai");

chai.use sinonChai

TABLE_LIST_RESPONSE_0 =
    Tables: []

TABLE_LIST_RESPONSE_1 =
    Tables: [
        Name: 'AllstarFull'
        Schema: 'data'
        Fields: []
    ,
        Name: 'Appearances'
        Schema: 'data'
        Fields: []
    ,
        Name: 'AwardsManagers'
        Schema: 'data'
        Fields: []
    ]

TABLE_LIST_RESPONSE_2 =
    Tables: [
        Name: 'AllstarFull'
        Fields: []
    ,
        Name: 'Appearances'
        Schema: 'data'
        Fields: []
    ]

TABLELIST0 = []
TABLELIST1 = ["data.Appearances", "data.AllstarFull", "data.AwardsManagers"]
TABLELIST2 = ["data.Appearances", "AllstarFull"]

describe "MetadataHandler", ->

    sandbox = null

    beforeEach =>
        sandbox = sinon.sandbox.create()
        sandbox.stub VirtDBConnector.log, "info"
        sandbox.stub VirtDBConnector.log, "debug"
        sandbox.stub VirtDBConnector.log, "trace"
        sandbox.stub VirtDBConnector.log, "error"

    afterEach =>
        CacheHandler._reset()
        sandbox.restore()

    describe "_createTableList", ->

        it "should give back emty array if there are no tables in the meta data message", ->
            handler = new MetadataHandler
            tablelist = handler._createTableList TABLE_LIST_RESPONSE_0
            tablelist.should.have.length 0

        it "should concatenate the schema and the table name if schema exists", ->
            handler = new MetadataHandler
            tablelist = handler._createTableList TABLE_LIST_RESPONSE_2
            tablelist.should.have.length 2
            tablelist.should.deep.include.members TABLELIST2

    describe "_filterTableList", ->

        it "should give back empty array if there are no tables", ->
            handler = new MetadataHandler
            tablelist = handler._filterTableList TABLELIST0, "", []
            tablelist.should.deep.equal TABLELIST0

        it "should give back all if there's no filter", ->
            handler = new MetadataHandler
            tablelist = handler._filterTableList TABLELIST1, "", []
            tablelist.should.deep.equal TABLELIST1

        it "should give back only the matched ones 1 match", ->
            handler = new MetadataHandler
            tablelist = handler._filterTableList TABLELIST1, "dsm", []
            tablelist.should.deep.equal ["data.AwardsManagers"]

        it "should give back only the matched ones 2 matches", ->
            handler = new MetadataHandler
            tablelist = handler._filterTableList TABLELIST1, "an", []
            tablelist.should.deep.equal ["data.Appearances", "data.AwardsManagers"]

        it "should give back nothing when no table is match with the query", ->
            handler = new MetadataHandler
            tablelist = handler._filterTableList TABLELIST1, "xy", []
            tablelist.should.deep.equal []

        it "should use the exact filter list first if both parameter provided", ->
            handler = new MetadataHandler
            tablelist = handler._filterTableList TABLELIST1, "an", ["data.Appearances"]
            tablelist.should.deep.equal ["data.Appearances"]

        it "should give back result set according to the filterlist", ->
            handler = new MetadataHandler
            tablelist = handler._filterTableList TABLELIST1, "sz", ["data.Appearances", "data.AwardsManagers"]
            tablelist.should.deep.equal ["data.Appearances", "data.AwardsManagers"]

    describe "_createTableListResult", ->

        it "should give empty response, if the count of tables is zero", ->
            exp_result =
                from: 0
                to: 0
                count: TABLELIST0.length
                results: TABLELIST0
            handler = new MetadataHandler
            result = handler._createTableListResult TABLELIST0, 0, 10
            result.should.deep.equal exp_result

        it "should give back all, if the count of tables is less than the requested quantity", ->
            exp_result =
                from: 0
                to: 2
                count: TABLELIST1.length
                results: TABLELIST1
            handler = new MetadataHandler
            result = handler._createTableListResult TABLELIST1, 0, 10
            result.should.deep.equal exp_result

        it "should give back subset, if the requested count of tables is less than the all table", ->
            exp_result =
                from: 1
                to: 2
                count: TABLELIST1.length
                results: ["data.AllstarFull", "data.AwardsManagers"]
            handler = new MetadataHandler
            result = handler._createTableListResult TABLELIST1, 2, 3
            result.should.deep.equal exp_result

    describe "_processTableListResponse", ->
        # it "should call the filter and reduce methods in the right order", ->
        it "give back empty list, if there are no tables", ->
            handler = new MetadataHandler
            exp_result =
                from: 0
                to: 0
                count: 0
                results: []
            result = handler._processTableListResponse TABLE_LIST_RESPONSE_0, "", 0, 10, []
            result.should.be.deep.equal exp_result

        it "should give back the processed result set", ->
            exp_result =
                from: 0
                to: 2
                count: TABLELIST1.length
                results: TABLELIST1

            handler = new MetadataHandler
            result = handler._processTableListResponse TABLE_LIST_RESPONSE_1, "", 0, 10, []
            result.should.have.deep.property "from", exp_result.from
            result.should.have.deep.property "to", exp_result.to
            result.should.have.deep.property "count", exp_result.count
            result.should.have.deep.property "results"
            result.results.should.have.length exp_result.results.length
            result.results.should.have.members exp_result.results

    describe "_convertTableToObject", ->

        it "should create, the right message", ->
            TABLE = "table1"
            SCHEMA = "schema1"
            TABLENAME = SCHEMA + "." + TABLE
            OBJ =
                Schema: SCHEMA,
                Name: TABLE

            handler = new MetadataHandler
            res = handler._convertTableToObject TABLENAME
            res.should.be.deep.equal OBJ

        it "should create, the right message when no schema available", ->
            TABLE = "table1"
            TABLENAME = TABLE
            OBJ =
                Name: TABLE

            handler = new MetadataHandler
            res = handler._convertTableToObject TABLENAME
            res.should.be.deep.equal OBJ

    describe "_createTableMetadataMessage", ->
        it "create the right message from a table name when schema is available", ->
            TABLE = "table1"
            SCHEMA = "schema1"
            TABLENAME = SCHEMA + "." + TABLE
            OBJ =
                Schema: SCHEMA,
                Name: TABLE
                WithFields: true

            handler = new MetadataHandler
            res = handler._createTableMetadataMessage TABLENAME
            res.should.be.deep.equal OBJ

        it "create the right message from a table name when schema is not available", ->
            TABLE = "table1"
            TABLENAME = TABLE
            OBJ =
                Schema: undefined
                Name: TABLE
                WithFields: true

            handler = new MetadataHandler
            res = handler._createTableMetadataMessage TABLENAME
            res.should.be.deep.equal OBJ

    describe "getTableList", ->

        it "should give back the cached version if it exists", ->

            PROVIDER = "prov"
            SEARCH = "search"
            FROM = 0
            TO = 10
            FILTERLIST = []
            KEY = "key"
            VALUE = "value"
            RESULT = "result"
            REQUEST = "req"

            handler = new MetadataHandler
            onReadySpy = sandbox.spy()
            _createTableListMessageStub = sandbox.stub handler, "_createTableListMessage"
            _createTableListMessageStub.returns REQUEST
            _generateCacheKeyStub = sandbox.stub handler, "_generateCacheKey"
            _generateCacheKeyStub.returns KEY
            cacheHandlerGetStub = sandbox.stub CacheHandler, "get"
            cacheHandlerGetStub.returns VALUE
            _processTableListResponseStub = sandbox.stub handler, "_processTableListResponse"
            _processTableListResponseStub.returns RESULT

            handler.getTableList PROVIDER, SEARCH, FROM, TO, FILTERLIST, onReadySpy

            _createTableListMessageStub.should.have.been.calledOnce
            _generateCacheKeyStub.should.have.been.calledOnce
            _generateCacheKeyStub.should.have.been.calledWithExactly PROVIDER, REQUEST
            cacheHandlerGetStub.should.have.been.calledOnce
            cacheHandlerGetStub.should.have.been.calledWithExactly KEY
            _processTableListResponseStub.should.calledOnce
            _processTableListResponseStub.should.calledWithExactly VALUE, SEARCH, FROM, TO, FILTERLIST
            onReadySpy.should.have.been.calledOnce
            onReadySpy.should.have.been.calledWithExactly null, RESULT

        it "should request the table list from the provider if it is not in cache and save it if it contains tables", ->

            PROVIDER = "prov"
            SEARCH = "search"
            FROM = 0
            TO = 10
            FILTERLIST = []
            METADATA =
                Tables: [
                    "table1"
                ,
                    "table2"
                ]
            KEY = "key"
            RESULT = "result"
            REQUEST = "req"
            ADDRESSES = ["addr1", "addr2"]

            handler = new MetadataHandler

            onReadySpy = sandbox.spy()
            _createTableListMessageStub = sandbox.stub handler, "_createTableListMessage"
            _createTableListMessageStub.returns REQUEST
            _generateCacheKeyStub = sandbox.stub handler, "_generateCacheKey"
            _generateCacheKeyStub.returns KEY
            cacheHandlerGetStub = sandbox.stub CacheHandler, "get"
            cacheHandlerGetStub.returns null
            conn = sinon.createStubInstance MetadataConnection
            endpointsGetMetaDataAddressStub = sandbox.stub Endpoints, "getMetadataAddress"
            endpointsGetMetaDataAddressStub.returns ADDRESSES
            metadataConnectionCreateInstanceStub = sandbox.stub MetadataConnection, "createInstance"
            metadataConnectionCreateInstanceStub.returns conn
            conn.getMetadata.callsArgWith 1, null, METADATA
            cacheHandlerSetStub = sandbox.stub CacheHandler, "set"
            _processTableListResponseStub = sandbox.stub handler, "_processTableListResponse"
            _processTableListResponseStub.returns RESULT

            handler.getTableList PROVIDER, SEARCH, FROM, TO, FILTERLIST, onReadySpy

            _createTableListMessageStub.should.have.been.calledOnce
            _generateCacheKeyStub.should.have.been.calledOnce
            _generateCacheKeyStub.should.have.been.calledWithExactly PROVIDER, REQUEST
            cacheHandlerGetStub.should.have.been.calledOnce
            cacheHandlerGetStub.should.have.been.calledWithExactly KEY
            endpointsGetMetaDataAddressStub.should.calledOnce
            endpointsGetMetaDataAddressStub.should.calledWithExactly PROVIDER
            metadataConnectionCreateInstanceStub.should.have.been.calledOnce
            metadataConnectionCreateInstanceStub.should.have.been.calledWithExactly ADDRESSES
            conn.getMetadata.should.have.been.calledOnce
            conn.getMetadata.should.have.been.calledWith REQUEST
            cacheHandlerSetStub.should.calledOnce
            cacheHandlerSetStub.should.calledWithExactly KEY, METADATA
            _processTableListResponseStub.should.calledOnce
            _processTableListResponseStub.should.calledWithExactly METADATA, SEARCH, FROM, TO, FILTERLIST
            onReadySpy.should.have.been.calledOnce
            onReadySpy.should.have.been.calledWithExactly null, RESULT

        it "should request the table list from the provider and don't save it if it not contains tables", ->

            PROVIDER = "prov"
            SEARCH = "search"
            FROM = 0
            TO = 10
            FILTERLIST = []
            METADATA =
                Tables: []
            KEY = "key"
            RESULT = "result"
            REQUEST = "req"
            ADDRESSES = ["addr1", "addr2"]

            handler = new MetadataHandler

            onReadySpy = sandbox.spy()
            _createTableListMessageStub = sandbox.stub handler, "_createTableListMessage"
            _createTableListMessageStub.returns REQUEST
            _generateCacheKeyStub = sandbox.stub handler, "_generateCacheKey"
            _generateCacheKeyStub.returns KEY
            cacheHandlerGetStub = sandbox.stub CacheHandler, "get"
            cacheHandlerGetStub.returns null
            conn = sinon.createStubInstance MetadataConnection
            endpointsGetMetaDataAddressStub = sandbox.stub Endpoints, "getMetadataAddress"
            endpointsGetMetaDataAddressStub.returns ADDRESSES
            metadataConnectionCreateInstanceStub = sandbox.stub MetadataConnection, "createInstance"
            metadataConnectionCreateInstanceStub.returns conn
            conn.getMetadata.callsArgWith 1, null, METADATA
            cacheHandlerSetStub = sandbox.stub CacheHandler, "set"
            _processTableListResponseStub = sandbox.stub handler, "_processTableListResponse"
            _processTableListResponseStub.returns RESULT

            handler.getTableList PROVIDER, SEARCH, FROM, TO, FILTERLIST, onReadySpy

            _createTableListMessageStub.should.have.been.calledOnce
            _generateCacheKeyStub.should.have.been.calledOnce
            _generateCacheKeyStub.should.have.been.calledWithExactly PROVIDER, REQUEST
            cacheHandlerGetStub.should.have.been.calledOnce
            cacheHandlerGetStub.should.have.been.calledWithExactly KEY
            endpointsGetMetaDataAddressStub.should.calledOnce
            endpointsGetMetaDataAddressStub.should.calledWithExactly PROVIDER
            metadataConnectionCreateInstanceStub.should.have.been.calledOnce
            metadataConnectionCreateInstanceStub.should.have.been.calledWithExactly ADDRESSES
            conn.getMetadata.should.have.been.calledOnce
            conn.getMetadata.should.have.been.calledWith REQUEST
            cacheHandlerSetStub.should.not.called
            _processTableListResponseStub.should.calledOnce
            _processTableListResponseStub.should.calledWithExactly METADATA, SEARCH, FROM, TO, FILTERLIST
            onReadySpy.should.have.been.calledOnce
            onReadySpy.should.have.been.calledWithExactly null, RESULT

    describe "getTableMetadata", ->

        it "should give back the cached version of meta data", ->

            PROVIDER = "prov"
            TABLE = "table"
            KEY = "key"
            VALUE = "value"
            RESULT = "result"
            REQUEST = "req"

            handler = new MetadataHandler
            onReadySpy = sandbox.spy()
            _createTableMetadataMessageStub = sandbox.stub handler, "_createTableMetadataMessage"
            _createTableMetadataMessageStub.returns REQUEST
            _generateCacheKeyStub = sandbox.stub handler, "_generateCacheKey"
            _generateCacheKeyStub.returns KEY
            cacheHandlerGetStub = sandbox.stub CacheHandler, "get"
            cacheHandlerGetStub.returns VALUE
            _processTableListResponseStub = sandbox.stub handler, "_processTableListResponse"
            _processTableListResponseStub.returns RESULT

            handler.getTableMetadata PROVIDER, TABLE, onReadySpy

            _createTableMetadataMessageStub.should.have.been.calledOnce
            _createTableMetadataMessageStub.should.have.been.calledWithExactly TABLE
            _generateCacheKeyStub.should.have.been.calledOnce
            _generateCacheKeyStub.should.have.been.calledWithExactly PROVIDER, REQUEST
            cacheHandlerGetStub.should.have.been.calledOnce
            cacheHandlerGetStub.should.have.been.calledWithExactly KEY
            onReadySpy.should.have.been.calledOnce
            onReadySpy.should.have.been.calledWithExactly null, VALUE

        it "should request the table meta data from the provider and save it in cache", ->

            PROVIDER = "prov"
            TABLE = "table"
            FILTERLIST = []
            METADATA =
                Tables: [
                    Name: "table1"
                    Fields: [
                        Name: "field1"
                    ,
                        Name: "field2"
                    ]
                ,
                    Name: "table2"
                    Fields: [
                        Name: "field3"
                    ,
                        Name: "field4"
                    ]
                ]
            KEY = "key"
            RESULT = "result"
            REQUEST = "req"
            ADDRESSES = ["addr1", "addr2"]

            handler = new MetadataHandler

            onReadySpy = sandbox.spy()
            _createTableMetadataMessageStub = sandbox.stub handler, "_createTableMetadataMessage"
            _createTableMetadataMessageStub.returns REQUEST
            _generateCacheKeyStub = sandbox.stub handler, "_generateCacheKey"
            _generateCacheKeyStub.returns KEY
            cacheHandlerGetStub = sandbox.stub CacheHandler, "get"
            cacheHandlerGetStub.returns null
            conn = sinon.createStubInstance MetadataConnection
            endpointsGetMetaDataAddressStub = sandbox.stub Endpoints, "getMetadataAddress"
            endpointsGetMetaDataAddressStub.returns ADDRESSES
            metadataConnectionCreateInstanceStub = sandbox.stub MetadataConnection, "createInstance"
            metadataConnectionCreateInstanceStub.returns conn
            conn.getMetadata.callsArgWith 1, null, METADATA
            cacheHandlerSetStub = sandbox.stub CacheHandler, "set"

            handler.getTableMetadata PROVIDER, TABLE, onReadySpy

            _createTableMetadataMessageStub.should.have.been.calledOnce
            _generateCacheKeyStub.should.have.been.calledOnce
            _generateCacheKeyStub.should.have.been.calledWithExactly PROVIDER, REQUEST
            cacheHandlerGetStub.should.have.been.calledOnce
            cacheHandlerGetStub.should.have.been.calledWithExactly KEY
            endpointsGetMetaDataAddressStub.should.calledOnce
            endpointsGetMetaDataAddressStub.should.calledWithExactly PROVIDER
            metadataConnectionCreateInstanceStub.should.have.been.calledOnce
            metadataConnectionCreateInstanceStub.should.have.been.calledWithExactly ADDRESSES
            conn.getMetadata.should.have.been.calledOnce
            conn.getMetadata.should.have.been.calledWith REQUEST
            cacheHandlerSetStub.should.calledOnce
            cacheHandlerSetStub.should.calledWithExactly KEY, METADATA
            onReadySpy.should.have.been.calledOnce
            onReadySpy.should.have.been.calledWithExactly null, METADATA

        it "should request the table meta data from the provider and not save it in cache", ->

            PROVIDER = "prov"
            TABLE = "table"
            FILTERLIST = []
            METADATA =
                Tables: []
            KEY = "key"
            RESULT = "result"
            REQUEST = "req"
            ADDRESSES = ["addr1", "addr2"]

            handler = new MetadataHandler

            onReadySpy = sandbox.spy()
            _createTableMetadataMessageStub = sandbox.stub handler, "_createTableMetadataMessage"
            _createTableMetadataMessageStub.returns REQUEST
            _generateCacheKeyStub = sandbox.stub handler, "_generateCacheKey"
            _generateCacheKeyStub.returns KEY
            cacheHandlerGetStub = sandbox.stub CacheHandler, "get"
            cacheHandlerGetStub.returns null
            conn = sinon.createStubInstance MetadataConnection
            endpointsGetMetaDataAddressStub = sandbox.stub Endpoints, "getMetadataAddress"
            endpointsGetMetaDataAddressStub.returns ADDRESSES
            metadataConnectionCreateInstanceStub = sandbox.stub MetadataConnection, "createInstance"
            metadataConnectionCreateInstanceStub.returns conn
            conn.getMetadata.callsArgWith 1, null, METADATA
            cacheHandlerSetStub = sandbox.stub CacheHandler, "set"

            handler.getTableMetadata PROVIDER, TABLE, onReadySpy

            _createTableMetadataMessageStub.should.have.been.calledOnce
            _generateCacheKeyStub.should.have.been.calledOnce
            _generateCacheKeyStub.should.have.been.calledWithExactly PROVIDER, REQUEST
            cacheHandlerGetStub.should.have.been.calledOnce
            cacheHandlerGetStub.should.have.been.calledWithExactly KEY
            endpointsGetMetaDataAddressStub.should.calledOnce
            endpointsGetMetaDataAddressStub.should.calledWithExactly PROVIDER
            metadataConnectionCreateInstanceStub.should.have.been.calledOnce
            metadataConnectionCreateInstanceStub.should.have.been.calledWithExactly ADDRESSES
            conn.getMetadata.should.have.been.calledOnce
            conn.getMetadata.should.have.been.calledWith REQUEST
            cacheHandlerSetStub.should.not.called
            onReadySpy.should.have.been.calledOnce
            onReadySpy.should.have.been.calledWithExactly null, METADATA

    it "should drop all cache entry for given provider", ->
        PROVIDER = "prov1"
        REQUEST1 =
            Tables: "someatbles23"
        METADATA1 = "esgsrgdgdrhdthgf"
        REQUEST2 =
            Tables: "someatbles56"
        METADATA2 = "dadadayuy.;"

        metadataHandler = new MetadataHandler
        key1 = metadataHandler._generateCacheKey PROVIDER, REQUEST1
        key2 = metadataHandler._generateCacheKey PROVIDER, REQUEST2
        CacheHandler.set key1, METADATA1
        CacheHandler.set key2, METADATA2

        metadataHandler.emptyProviderCache PROVIDER
        result1 = CacheHandler.get key1
        should.not.exist result1
        result2 = CacheHandler.get key2
        should.not.exist result2
