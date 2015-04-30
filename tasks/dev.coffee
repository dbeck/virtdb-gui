gulp = require 'gulp'

EXPRESS_ROOT = __dirname
LIVERELOAD_PORT = 3001

lr = null

gulp.task 'start-livereload-server', ->
    lr = require('tiny-lr')()
    lr.listen LIVERELOAD_PORT

notifyLivereload = (event) ->
    fileName = require('path').relative EXPRESS_ROOT, event.path
    lr.changed
        body:
            files: [fileName]

gulp.task 'watch', ['client-watch', 'server-watch'], ->
    gulp.watch ['static/**/*.*'], notifyLivereload
