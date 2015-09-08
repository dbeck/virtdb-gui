router = require('express').Router();
UserManager = require './user_manager'
DBConfig = require './db_config_connector'
VirtDB = require "virtdb-connector"
log = VirtDB.log
V_ = log.Variable

router.get "/"
#, timeout(Config.getCommandLineParameter("timeout"))
, (req, res, next) ->
    res.json req.user

router.put "/:name", (req, res, err) ->
    UserManager.updateUser req.params.name, req.body.password, req.body.isAdmin, req.user.token, (err, data) ->
        if err?
            res.status(500).send()
        else
            res.status(200).send()
            DBConfig.updateUser req.params.name, req.body.password, (err, result) ->
                if err?
                    log.error "Error during updating user in the datatabase", (V_ err)


router.post "/", (req, res, err) ->
    UserManager.createUser req.body.name, req.body.password, req.body.isAdmin, req.user.token, (err, data) ->
        if err?
            res.status(500).send()
        else
            res.status(200).send()
            DBConfig.createUser req.body.name, req.body.password, (err, result) ->
                if err?
                    log.error "Error during creating user in the datatabase", (V_ err)

router.delete "/:name", (req, res, err) ->
    UserManager.deleteUser req.params.name, req.user.token, (err, data) ->
        if err?
            res.status(500).send()
        else
            res.status(200).send()
            DBConfig.deleteUser req.params.name, (err, result) ->
                if err?
                    log.error "Error during deleting user in the datatabase", (V_ err)

router.get "/list", (req, res, err) ->
    UserManager.listUsers req.user.token, (err, users) ->
        if err?
            res.status(500).send()
        else if users?
            res.status(200).send users
        else
            res.status(500).send()

module.exports = router