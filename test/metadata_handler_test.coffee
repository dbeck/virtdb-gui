# VirtDBConnector = require "virtdb-connector"
# MetadataHandler = require "../src/scripts/server/meta_data_handler"
# CacheHandler = require "../src/scripts/server/cache_handler"
#
# chai = require "chai"
# chai.should()
# expect = chai.expect
#
# sinon = require "sinon"
# sinonChai = require("sinon-chai");
#
# chai.use sinonChai
#
# TABLE_LIST_RESPONSE_0 =
#     Tables: []
#
# TABLE_LIST_RESPONSE_1 =
#     Tables: [
#         Name: 'AllstarFull'
#         Schema: 'data'
#         Fields: []
#     ,
#         Name: 'Appearances'
#         Schema: 'data'
#         Fields: []
#     ,
#         Name: 'AwardsManagers'
#         Schema: 'data'
#         Fields: []
#     ]
#
# TABLE_LIST_RESPONSE_2 =
#     Tables: [
#         Name: 'AllstarFull'
#         Fields: []
#     ,
#         Name: 'Appearances'
#         Schema: 'data'
#         Fields: []
#     ]
#
# TABLELIST0 = []
# TABLELIST1 = ["data.Appearances", "data.AllstarFull", "data.AwardsManagers"]
# TABLELIST2 = ["data.Appearances", "AllstarFull"]
#
# describe "MetadataHandler", ->
#
#     sandbox = null
#
#     beforeEach =>
#         sandbox = sinon.sandbox.create()
#         sandbox.stub(VirtDBConnector, "log")
#
#     afterEach =>
#         sandbox.restore()
#
#     it "_createTableList should give back emty array if there are no tables in the meta data message", ->
#         handler = new MetadataHandler
#         tablelist = handler._createTableList TABLE_LIST_RESPONSE_0
#         tablelist.should.have.length 0
#
#     it "_createTableList should concatenate the schema and the table name if schema exists", ->
#         handler = new MetadataHandler
#         tablelist = handler._createTableList TABLE_LIST_RESPONSE_2
#         tablelist.should.have.length 2
#         tablelist.should.deep.include.members TABLELIST2
#
#     it "_filterTableList should give back empty array if there are no tables", ->
#         handler = new MetadataHandler
#         tablelist = handler._filterTableList TABLELIST0, "", []
#         tablelist.should.deep.equal TABLELIST0
#
#     it "_filterTableList should give back all if there's no filter", ->
#         handler = new MetadataHandler
#         tablelist = handler._filterTableList TABLELIST1, "", []
#         tablelist.should.deep.equal TABLELIST1
#
#     it "_filterTableList should give back only the matched ones 1 match", ->
#         handler = new MetadataHandler
#         tablelist = handler._filterTableList TABLELIST1, "dsm", []
#         tablelist.should.deep.equal ["data.AwardsManagers"]
#
#     it "_filterTableList should give back only the matched ones 2 matches", ->
#         handler = new MetadataHandler
#         tablelist = handler._filterTableList TABLELIST1, "an", []
#         tablelist.should.deep.equal ["data.Appearances", "data.AwardsManagers"]
#
#     # it "_filterTableList should give back nothing when no table is match with the query", ->
#     # it "_filterTableList should use the exact filter list first if both parameter provided", ->
#     # it "_filterTableList should give back result set according to the filterlist", ->
#
#     it "_createTableListResult should give empty response, if the count of tables is zero", ->
#         exp_result =
#             from: 0
#             to: 0
#             count: TABLELIST0.length
#             results: TABLELIST0
#         handler = new MetadataHandler
#         result = handler._createTableListResult TABLELIST0, 0, 10
#         result.should.deep.equal exp_result
#
#     it "_createTableListResult should give back all, if the count of tables is less than the requested quantity", ->
#         exp_result =
#             from: 0
#             to: 2
#             count: TABLELIST1.length
#             results: TABLELIST1
#         handler = new MetadataHandler
#         result = handler._createTableListResult TABLELIST1, 0, 10
#         result.should.deep.equal exp_result
#
#     it "_createTableListResult should give back subset, if the requested count of tables is less than the all table", ->
#         exp_result =
#             from: 1
#             to: 2
#             count: TABLELIST1.length
#             results: ["data.AllstarFull", "data.AwardsManagers"]
#         handler = new MetadataHandler
#         result = handler._createTableListResult TABLELIST1, 2, 3
#         result.should.deep.equal exp_result
#
#     # it "_processTableListResponse should call the filter and reduce methods in the right order", ->
#     it "_processTableListResponse give back empty list, if there are no tables", ->
#         handler = new MetadataHandler
#         exp_result =
#             from: 0
#             to: 0
#             count: 0
#             results: []
#         result = handler._processTableListResponse TABLE_LIST_RESPONSE_0, "", 0, 10, []
#         result.should.be.deep.equal exp_result
#
#     it "_processTableListResponse should give back the processed result set", ->
#         exp_result =
#             from: 0
#             to: 2
#             count: TABLELIST1.length
#             results: TABLELIST1
#
#         handler = new MetadataHandler
#         result = handler._processTableListResponse TABLE_LIST_RESPONSE_1, "", 0, 10, []
#         result.should.have.deep.property "from", exp_result.from
#         result.should.have.deep.property "to", exp_result.to
#         result.should.have.deep.property "count", exp_result.count
#         result.should.have.deep.property "results"
#         result.results.should.have.length exp_result.results.length
#         result.results.should.have.members exp_result.results
#
#     it "_convertTableToObject should create, the right message", ->
#         TABLE = "table1"
#         SCHEMA = "schema1"
#         TABLENAME = SCHEMA + "." + TABLE
#         OBJ =
#             Schema: SCHEMA,
#             Name: TABLE
#
#         handler = new MetadataHandler
#         res = handler._convertTableToObject TABLENAME
#         res.should.be.deep.equal OBJ
#
#     it "_convertTableToObject should create, the right message when no schema available", ->
#         TABLE = "table1"
#         TABLENAME = TABLE
#         OBJ =
#             Name: TABLE
#
#         handler = new MetadataHandler
#         res = handler._convertTableToObject TABLENAME
#         res.should.be.deep.equal OBJ
#
#     it "_createTableMetadataMessage create the right message from a table name when schema is available", ->
#         TABLE = "table1"
#         SCHEMA = "schema1"
#         TABLENAME = SCHEMA + "." + TABLE
#         OBJ =
#             Schema: SCHEMA,
#             Name: TABLE
#             WithFields: true
#
#         handler = new MetadataHandler
#         res = handler._createTableMetadataMessage TABLENAME
#         res.should.be.deep.equal OBJ
#
#     it "_createTableMetadataMessage create the right message from a table name when schema is not available", ->
#         TABLE = "table1"
#         TABLENAME = TABLE
#         OBJ =
#             Schema: undefined
#             Name: TABLE
#             WithFields: true
#
#         handler = new MetadataHandler
#         res = handler._createTableMetadataMessage TABLENAME
#         res.should.be.deep.equal OBJ
