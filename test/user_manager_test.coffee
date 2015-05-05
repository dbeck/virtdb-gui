# UserManager = require "../src/scripts/server/user_manager"
# zmq     = require 'zmq'
# SecurityProto = (require "virtdb-proto").security

# chai = require "chai"
# should = chai.should()
# sinon = require "sinon"
# sinonChai = require "sinon-chai"
# chai.use sinonChai

# class SocketStub
#     receive: null
#     isBound: false
#     setsockopt: null
#     sentData: null
#     constructor: ->
#         @setsockopt = sinon.spy()
#         @sentData = []
#     on: (message, @receive) =>
#     bind: (address, callback) =>
#         @isBound = true
#         callback()
#     close: () =>
#     send: (data) =>
#         @sentData.push data

# describe "UserManager", ->
#     sandbox = null
#     socket = null
#     connectStub = null

#     beforeEach =>
#         sandbox = sinon.sandbox.create()
#         socket = new SocketStub
#         connectStub = sandbox.stub zmq, "socket", (type) ->
#             type.should.equal 'rep'
#             return socket

#     it "should send"
#     it "should send"
