var gulp = require('gulp');
var coffee = require('gulp-coffee');
var sourcemaps = require('gulp-sourcemaps');
var jade = require('gulp-jade');
var stylus = require('gulp-stylus');
var mainBowerFiles = require('main-bower-files');
var server = require('gulp-express');

var EXPRESS_ROOT = __dirname;
var LIVERELOAD_PORT = 3001;
var NOT_LIVERELOAD_PORT = 3002;


var lr;
gulp.task('start-livereload-server', function() {
  lr = require('tiny-lr')();
  lr.listen(LIVERELOAD_PORT);
});

function notifyLivereload(event) {
  var fileName = require('path').relative(EXPRESS_ROOT, event.path);
  lr.changed({
    body: {
      files: [fileName]
    }
  });
}

gulp.task('compile-stylus', function() {
    gulp.src('./src/styles/*.styl')
        .pipe(stylus())
        .pipe(gulp.dest('./static/styles'));
})

gulp.task('compile-jade', function() {
    gulp.src(['./src/pages/*.jade', '!./src/pages/index.jade'])
        .pipe(jade({pretty: true}))
        .pipe(gulp.dest('./static/pages'));
})

gulp.task('copy-index-to-static', function(){
    gulp.src('./src/pages/index.jade')
        .pipe(gulp.dest('./static/pages'));
});

gulp.task('compile-client-coffee', function() {
    var sources = './src/scripts/client/*.coffee';
    var destDir = './static/scripts/';
    gulp.src(sources)
        .pipe(sourcemaps.init())
        .pipe(coffee({bare: true}).on('error', console.error))
        .pipe(sourcemaps.write('.'))
        .pipe(gulp.dest(destDir))
});

gulp.task('compile-server-coffee', function() {
    var sources = './src/scripts/server/*.coffee';
    var destDir = './src/scripts/server/out';
    gulp.src(sources)
        .pipe(sourcemaps.init())
        .pipe(coffee({bare: true}).on('error', console.error))
        .pipe(sourcemaps.write('.'))
        .pipe(gulp.dest(destDir))
    server.run();
})

gulp.task('start-dev-server', [
    'collect-libs',
    'compile-server-coffee',
    'copy-index-to-static',
    'compile-client-coffee',
    'compile-jade',
    'compile-stylus',
    'start-livereload-server'
    ],
    function () {
        server.run({
            file: 'app.js',
            env: 'development',
            port: NOT_LIVERELOAD_PORT
        });
})

gulp.task('collect-libs', function() {
    var files = mainBowerFiles();
    gulp.src(files)
        .pipe(gulp.dest('static/libs'));
});

gulp.task('watch', function()
{
    //Reloader watch
    gulp.watch(['static/**/*.*'], notifyLivereload);

    //Client side watch
    gulp.watch(['src/pages/**/*.jade'], ['compile-jade']);
    gulp.watch(['src/styles/**/*.styl'], ['compile-stylus']);
    gulp.watch(['src/scripts/client/**/*.coffee'], ['compile-client-coffee']);
    gulp.watch(['src/pages/index.jade'], ['copy-index-to-static']);

    //Server side watch
    gulp.watch(['src/scripts/server/**/*.coffee'], ['compile-server-coffee']);

    //Third-party watch
    gulp.watch(['bower.json'], ['collect-libs']);
});

gulp.task('default', [
    'watch',
    'start-dev-server',
]);
