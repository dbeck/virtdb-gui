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
                items = reply.map (item) ->
                    ret = {}
                    ret.Name = item.Name
                    ret.OK = item.OK
                    ret.UpdatedEpoch = item.UpdatedEpoch
                    ret.Events = item.Events
                        .filter (event) ->
                            return event.Request.Type isnt 'REPORT_STATS'
                        .map (event) ->
                            flatEvent = {}
                            flatEvent.Epoch = event.Epoch
                            flatEvent.Type = event.Request.Type
                            switch event.Request.Type
                                when 'COMPONENT_ERROR'
                                    flatEvent.SubType = event.Request.CompErr.Type
                                    flatEvent.ReportedBy = event.Request.CompErr.ReportedBy
                                    flatEvent.Message = event.Request.CompErr.Message
                                when 'REQUEST_ERROR'
                                    flatEvent.SubType = event.Request.ReqErr.Type
                                    flatEvent.ReportedBy = event.Request.ReqErr.ReportedBy
                                    flatEvent.Message = event.Request.ReqErr.Message
                                when 'SET_STATE'
                                    flatEvent.ReportedBy = item.Name
                                    flatEvent.SubType = event.Request.SetSt.Type
                                    flatEvent.Message = event.Request.SetSt.Msg
                            return flatEvent
                    ret.Stats = []
                    stats = item.Events
                        .filter (event) ->
                            return event.Request.Type is 'REPORT_STATS'
                        .map (event) ->
                            return event.Request.RepStats.Stats
                        .sort (a, b) ->
                            return a.Epoch - b.Epoch
                    if stats.length > 0
                        ret.Stats = stats[stats.length - 1]
                    return ret
                cb null, items
            else
                cb err, null

router.get '/monitoring'
    , auth.ensureAuthenticated
    , timeout(Config.getCommandLineParameter('timout'))
, (req, res, next) ->
    MonitoringClient.get (err, results) ->
        if err?
            res.status(500).send()
            return
        res.json results
