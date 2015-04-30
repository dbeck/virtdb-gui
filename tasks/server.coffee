gulp = require 'gulp'
coffee = require 'gulp-coffee'
sourcemaps = require 'gulp-sourcemaps'

gulp.task 'compile-server-coffee', ->
    sources = './src/scripts/server/*.coffee'
    destDir = './server'
    gulp.src sources
        .pipe sourcemaps.init()
        .pipe coffee
            bare: true
        .on 'error', console.error
        .pipe sourcemaps.write '.'
        .pipe gulp.dest destDir

gulp.task 'server-watch', ->
    gulp.watch ['src/scripts/server/**/*.coffee'], ['compile-server-coffee']
    gulp.watch ['bower.json'], ['collect-libs']

gulp.task 'server-build', ['compile-server-coffee']
