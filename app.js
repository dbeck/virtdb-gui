var config = require("./server/config")
var VirtDBLoader = require("./server/virtdb_loader")
var express = require('express');
var path = require('path');
var favicon = require('static-favicon');
var logger = require('morgan');
var cookieParser = require('cookie-parser');
var bodyParser = require('body-parser');
var fs = require('fs');

var EXPRESS_PORT = config.getCommandLineParameter("port")
var LIVERELOAD_PORT = 3001;

var app = module.exports.app = exports.app = express();

var allowCrossDomain = function(req, res, next) {
// Uncomment to allow CORS
//     res.header('Access-Control-Allow-Origin', '*');
//     res.header('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE');
//     res.header('Access-Control-Allow-Headers', 'Content-Type');

    next();
}

// Authentication

var passport = require('passport');
var BasicStrategy = require('passport-http').BasicStrategy;
var users = [];
try {
    var authFile = config.getCommandLineParameter("authFile");
    console.log(authFile);
    users = JSON.parse(fs.readFileSync(authFile));
} catch (ex) {
    console.error(ex);
}

function findByUsername(username, fn) {
  for (var i = 0, len = users.length; i < len; i++) {
    var user = users[i];
    if (user.username === username) {
      return fn(null, user);
    }
  }
  return fn(null, null);
}

// Use the BasicStrategy within Passport.
//   Strategies in Passport require a `verify` function, which accept
//   credentials (in this case, a username and password), and invoke a callback
//   with a user object.
passport.use(new BasicStrategy({
  },
  function(username, password, done) {
    // asynchronous verification, for effect...
    process.nextTick(function () {
      
      // Find the user by username.  If there is no user with the given
      // username, or the password is not correct, set the user to `false` to
      // indicate failure.  Otherwise, return the authenticated `user`.
      findByUsername(username, function(err, user) {
        if (err) { return done(err); }
        if (!user) { return done(null, false); }
        if (user.password != password) { return done(null, false); }
        return done(null, user);
      })
    });
  }
));

app.use(passport.initialize());
// Authentication end 


app.set('view engine', 'jade');
app.set('views', path.join(__dirname, 'static/pages'));

app.use(favicon());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded());
app.use(cookieParser());
app.use(allowCrossDomain);
app.use(express.static(path.join(__dirname, 'static')));

if (app.get('env') === 'development') {
    app.use(require('connect-livereload')({
    port: LIVERELOAD_PORT
  }));
}

var index = require('./server/index_route');
var api = require('./server/api_route');
app.use('/api', api);
app.use('/', index);

server = app.listen(EXPRESS_PORT, function() {
    console.log('Listening on port %d', server.address().port);
});
VirtDBLoader.start();
