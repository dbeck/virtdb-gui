var express = require('express');
var router = express.Router();
var ServiceConfigConnector = require('../logic/svcconfig_connector.js');

/* GET home page. */
router.get('/', function(req, res) {
    res.render('index');
});

router.get('/endpoints', function(req, res) {

    var onEndpointsReceived = function(endpoints) {
        res.render('endpoints', { endpoints: endpoints });
    }

    var svc_config = new ServiceConfigConnector();
    svc_config.connect();
    svc_config.getEndpoints(onEndpointsReceived);

});

module.exports = router;
