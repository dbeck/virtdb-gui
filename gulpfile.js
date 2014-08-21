var gulp = require('gulp');
var coffee = require('gulp-coffee');
var spawn = require('child_process').spawn;
var sourcemaps = require('gulp-sourcemaps');
var wait = require('gulp-wait')
var browserSync = require('browser-sync');
var node;

/**
 * $ gulp server
 * description: launch the server. If there's a server already running, kill it.
 */
// gulp.task('express-server', function() {
//   if (node) node.kill()
//   node = spawn('node', ['./bin/www'], {stdio: 'inherit'})
//   node.on('close', function (code) {
//     if (code === 8) {
//       console.log('Error detected, waiting for changes...');
//       gulp.start('express-server');
//     }
//   });
//   node.on('error', function () {
//     console.log('Error detected, waiting for changes...');
//     gulp.start('express-server');
//   });
//   wait(1500);
// })

gulp.task('client-side-coffee', function() {
    var scriptDir = './public/javascripts/';
    gulp.src(scriptDir + '*.coffee')
        .pipe(sourcemaps.init())
        .pipe(coffee({bare: true}))
        .pipe(sourcemaps.write(scriptDir))
        .pipe(gulp.dest(scriptDir))
});

// gulp.task('server-side-coffee', function() {
//     gulp.src('./public/javascripts/*.coffee')
//         .pipe(sourcemaps.init())
//         .pipe(coffee({bare: true}))
//         .pipe(sourcemaps.write('.'))
//         .pipe(gulp.dest('./public/javascripts'))
// });

// Reload all Browsers
gulp.task('browser-sync-reload', function () {
    browserSync.reload();
});

// Start the server
gulp.task('browser-sync', function() {
    browserSync.init(null, {
  		proxy: {
  			host: "http://localhost",
  			port: "3000"
  		}
	});
});

gulp.task('watch', function()
{
    //Client side watch
    gulp.watch(['views/*.jade'], ['browser-sync-reload']);
    gulp.watch(['public/stylesheets/*.styl'], ['browser-sync-reload']);
    gulp.watch(['public/javascripts/*.coffee'], ['client-side-coffee', 'browser-sync-reload']);

    //Server side watch
    // gulp.watch(['routes/*.js'], ['express-server', 'browser-sync-reload']);
    // gulp.watch(['*.js'], ['express-server', ,'browser-sync-reload']);
});

gulp.task('default', ['browser-sync', 'watch']);
