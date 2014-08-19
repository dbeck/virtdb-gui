var gulp = require('gulp');
var coffee = require('gulp-coffee');
var spawn = require('child_process').spawn;
var sourcemaps = require('gulp-sourcemaps');
var browserSync = require('browser-sync');
var node;

/**
 * $ gulp server
 * description: launch the server. If there's a server already running, kill it.
 */
// gulp.task('server', function() {
//   if (node) node.kill()
//   node = spawn('node', ['out/csvDataSource.js'], {stdio: 'inherit'})
//   node.on('close', function (code) {
//     if (code === 8) {
//       console.log('Error detected, waiting for changes...');
//       gulp.start('server');
//     }
//   });
//   node.on('error', function () {
//     console.log('Error detected, waiting for changes...');
//     gulp.start('server');
//   });
// })

gulp.task('coffee', function() {
    gulp.src('./public/javascripts/*.coffee')
        .pipe(sourcemaps.init())
        .pipe(coffee({bare: true}))
        .pipe(sourcemaps.write('.'))
        .pipe(gulp.dest('./public/javascripts'))
});

// Reload all Browsers
gulp.task('bs-reload', function () {
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
    gulp.watch(['./*.coffee'], ['coffee']);
    gulp.watch(['views/*.jade'], ['bs-reload']);
    gulp.watch(['public/stylesheets/*.styl'], ['bs-reload']);
    gulp.watch(['public/javascripts/*.js'], ['bs-reload']);
});

gulp.task('default', ['watch', 'browser-sync']);
