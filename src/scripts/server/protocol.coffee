Proto = require "virtdb-proto"
SecurityProto = Proto.security
DBConfigProto = Proto.db_config
VirtDB = require 'virtdb-connector'
Const = VirtDB.Const

sendUserManagerRequest = (endpointType, message, callback) ->
    try
        request = SecurityProto.serialize message, 'virtdb.interface.pb.UserManagerRequest'
        VirtDB.sendRequest Const.SECURITY_SERVICE, endpointType, request, parseUserManagerReply callback
        VirtDB.MonitoringService.bumpStatistic "User manager request sent"
    catch ex
        callback ex, null

parseUserManagerReply = (callback) ->
    return (err, message) ->
        try
            if err?
                throw err
            try
                reply = SecurityProto.parse message, 'virtdb.interface.pb.UserManagerReply'
            catch ex
                VirtDBConnector.MonitoringService.requestError Const.SECURITY_SERVICE, Const.REQUEST_ERROR.INVALID_REQUEST, ex.toString()
                throw ex
            if not reply?
                throw new Error "Problem with socket communication."
            if reply.Type is "ERROR_MSG"
                throw new Error reply.Err.Msg
            callback null, reply
        catch ex
            callback ex, null

sendDBConfig = (service, message, callback) ->
    serializedMessage = DBConfigProto.serialize message, "virtdb.interface.pb.DBConfigRequest"
    VirtDB.sendRequest service, Const.ENDPOINT_TYPE.DB_CONFIG, serializedMessage, (err, message) =>
        if err?
            callback err, null
            return
        try
            reply = DBConfigProto.parse message, "virtdb.interface.pb.DBConfigReply"
            callback null, reply
        catch ex
            VirtDB.MonitoringService.requestError @service, Const.REQUEST_ERROR.INVALID_REQUEST, ex.toString()
            callback ex, null
    VirtDB.MonitoringService.bumpStatistic "DB config request sent"

module.exports.sendUserManagerRequest = sendUserManagerRequest
module.exports.sendDBConfig = sendDBConfig


