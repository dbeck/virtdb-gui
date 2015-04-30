gulp = require 'gulp'
express = require 'gulp-express'
require 'coffee-script/register'

test = require './tasks/test.coffee'
client = require './tasks/client.coffee'
server = require './tasks/server.coffee'
dev = require './tasks/dev.coffee'

NOT_LIVERELOAD_PORT = 3002

startExpress = ->
    express.run
        env: 'development'
        file: 'app.js'
        port: NOT_LIVERELOAD_PORT

gulp.task 'start-dev-server', ['prepare-files','start-livereload-server'], startExpress
gulp.task 'restart-express', ['compile-server-coffee'], startExpress
gulp.task 'build', ['client-build', 'server-build']

# Both will be deprecated and replace by the build task when that is introduced to all projects
gulp.task 'prepare-files', ['client-build', 'server-build']
gulp.task 'coffee', ['prepare-files']

gulp.task 'default', [
    'watch',
    'prepare-files',
    'start-livereload-server'
]
