router = require './router'
auth = require './authentication'
Config = require "./config"
timeout = require "connect-timeout"
Proto = require 'virtdb-proto'
Connector = require 'virtdb-connector'
Const = Connector.Const

createRequest = (request) ->
    try
        type = 'virtdb.interface.pb.MonitoringRequest'
        return Proto.monitoring.serialize request, type
    catch ex
        console.error ex

parseReply = (callback) ->
    return (err, reply) ->
        try
            if not err? and reply?
                type = 'virtdb.interface.pb.MonitoringReply'
                reply = Proto.monitoring.parse reply, type
                if reply.Type is 'ERROR_MSG'
                    err = new Error reply.Err.Msg
        catch ex
            err ?= ex
        finally
            callback? err, reply

MonitoringClient =
    get: (cb) ->
        request = createRequest
            Type: 'GET_STATES'

        Connector.sendRequest Const.MONITORING_SERVICE, 'MONITORING', request, parseReply (err, reply) ->
            if not err?
                reply = reply.States?.States
            cb err, reply

router.get '/monitoring'
    , auth.ensureAuthenticated
    , timeout(Config.getCommandLineParameter('timout'))
, (req, res, next) ->
    MonitoringClient.get (err, results) ->
        if err?
            res.status(500).send()
            return
        res.json results
