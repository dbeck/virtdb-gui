gulp = require 'gulp'
coffee = require 'gulp-coffee'
sourcemaps = require 'gulp-sourcemaps'

compileCoffee = (sources, destDir) ->
    gulp.src sources
        .pipe sourcemaps.init()
        .pipe coffee
            bare: true
        .on 'error', console.error
        .pipe sourcemaps.write '.'
        .pipe gulp.dest destDir

gulp.task 'compile-server-coffee', ->
    sources = './src/scripts/server/*.coffee'
    destDir = './server'
    compileCoffee sources, destDir

gulp.task 'compile-app-coffee', ->
    compileCoffee 'app.coffee', '.'

gulp.task 'server-watch', ->
    gulp.watch ['src/scripts/server/**/*.coffee'], ['update-server']
    gulp.watch ['bower.json'], ['collect-libs']

gulp.task 'server-build', ['compile-server-coffee', 'compile-app-coffee']
