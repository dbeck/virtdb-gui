var config = require("./src/scripts/server/out/config")
var express = require('express');
var path = require('path');
var favicon = require('static-favicon');
var logger = require('morgan');
var cookieParser = require('cookie-parser');
var bodyParser = require('body-parser');
var VirtDBLoader = require("./src/scripts/server/out/virtdb_loader")


var EXPRESS_PORT = config.getCommandLineParameter("port")
var LIVERELOAD_PORT = 3001;

var app = module.exports.app = exports.app = express();

app.set('view engine', 'jade');
app.set('views', path.join(__dirname, 'static/pages'));

app.use(favicon());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded());
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'static')));

if (app.get('env') === 'development') {
    app.use(require('connect-livereload')({
    port: LIVERELOAD_PORT
  }));
}

var index = require('./src/scripts/server/out/index_route');
var api = require('./src/scripts/server/out/api_route');
app.use('/api', api);
app.use('/', index);

var server;
var startApp = function () {
    server = app.listen(EXPRESS_PORT, function() {
        console.log('Listening on port %d', server.address().port);
    });
}

VirtDBLoader.start(startApp);