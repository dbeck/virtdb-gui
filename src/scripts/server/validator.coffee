VirtDBConnector = require "virtdb-connector"
log = VirtDBConnector.log
V_ = log.Variable

module.exports = (params, paramType) ->
    return (req, res, next) ->
        if not paramType?
            paramType = "body"
        try
            for param of params
                value = req[paramType]?[param]?
                if params[param].required and not value
                    throw new Error("Missing required parameter: #{param}")
                if params[param].validate? and not params[param].validate(value)
                    throw new Error("Invalid parameter: #{param}")
            next()
        catch ex
            log.error "Endpoint called with bad parameters", V_(path), V_(ex)
            res.status(400).send()

