SecurityProto = (require "virtdb-proto").security
VirtDB = require 'virtdb-connector'
Const = VirtDB.Const

parseUserMessage = (callback) ->
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

sendSecurityMessage = (endpointType, message, callback) ->
    try
        request = SecurityProto.serialize message, 'virtdb.interface.pb.UserManagerRequest'
        VirtDB.sendRequest Const.SECURITY_SERVICE, endpointType, request, parseUserMessage callback
    catch ex
        callback ex, null

module.exports.sendSecurityMessage = sendSecurityMessage


