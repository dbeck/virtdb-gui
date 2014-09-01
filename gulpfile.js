var gulp = require('gulp');
var coffee = require('gulp-coffee');
var spawn = require('child_process').spawn;
var sourcemaps = require('gulp-sourcemaps');
var nodemon = require('gulp-nodemon');
var jade = require('gulp-jade');
var stylus = require('gulp-stylus');
var mainBowerFiles = require('main-bower-files');

var node;
var lr;

var EXPRESS_ROOT = __dirname;
var LIVERELOAD_PORT = 3001;

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
        .pipe(coffee({bare: true}))
        .pipe(sourcemaps.write('.'))
        .pipe(gulp.dest(destDir))
});

gulp.task('compile-server-coffee', function() {
    var sources = './src/scripts/server/*.coffee';
    var destDir = './src/scripts/server/out';
    gulp.src(sources)
        .pipe(sourcemaps.init())
        .pipe(coffee({bare: true}))
        .pipe(sourcemaps.write('.'))
        .pipe(gulp.dest(destDir))
})

gulp.task('start-dev-server', function () {
    nodemon({
        'script': './bin/www',
        'ext': 'yyy',
        'watch': ['src/scripts/server/out']
    })
    .on('restart', function () {
        console.log('Server restarted!')
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
    'collect-libs',
    'compile-server-coffee',
    'compile-client-coffee',
    'compile-jade',
    'compile-stylus',
    'watch',
    'start-dev-server',
    'start-livereload-server',
]);
