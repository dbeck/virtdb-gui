zmq = require 'zmq'
Const = (require "virtdb-connector").Const
log = (require "virtdb-connector").log
V_ = log.Variable
SecurityProto = (require "virtdb-proto").security
Endpoints = require "./endpoints"
require("source-map-support").install()

class UserManagerConnection

    socket: null
    callback: null

    constructor: ->

    send: (message, callback) =>
        @_initSocket()
        @callback = callback
        try
            socketMessage = SecurityProto.serialize message, "virtdb.interface.pb.UserManagerRequest"
            @socket.send socketMessage
        catch ex
            log.error "Problem during sending UserManagerRequest message", V_(ex)
            @callback null

    _initSocket: =>
        try
            @socket = zmq.socket Const.ZMQ_REQ
            for addr in Endpoints.getUserManagerAddress()
                @socket.connect addr
            @socket.on "message", @_onMessage
        catch ex
            log.error "Problem during initiating UserManager socket", V_(ex)
            @callback null        

    _onMessage: (message) =>
        try 
            reply = SecurityProto.parse message, "virtdb.interface.pb.UserManagerReply"
            @callback reply
        catch ex
            log.error "Problem during parsing UserManagerReply", V_(ex)
            @callback null

module.exports = UserManagerConnection
