var express = require('express');
var router = express.Router();
var ServiceConfigConnector = require('../logic/svcconfig_connector.js');
var MetadataConnector = require('../logic/meta_data_connector.js');

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

router.get('/metadata', function(req, res) {

    var onMetadata = function(metadata) {
        res.render('metadata', { tables: metadata.Tables });
    }

    var metadata = new MetadataConnector();
    var schema = "data";
    var regexp = '.*';
    metadata.connect(req.param("url"));
    metadata.getMetadata(schema, regexp, onMetadata);

});

module.exports = router;
