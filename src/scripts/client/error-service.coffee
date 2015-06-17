app = require './virtdb-app.js'
module.exports = app.factory 'ErrorService', ['$rootScope', ($rootScope) ->
    new class ErrorService

        constructor: () ->
            @errorListeners = []

        addErrorListener: (callback) =>
            @errorListeners.push callback
            return

        showDesktopNotification = (message) ->
            if not window.Notification? or Notification.premission is 'denied'
                return false

            notification = new Notification 'VirtDB Error',
                body: message
                icon: '/images/final_logo_ws_compressed.png'

            if autoHide()
                hideNotification = ->
                    timeout = $rootScope.Settings['Client/NotificationCloseTimeout']
                    timeout ?= 2000
                    setTimeout ->
                        notification.close()
                        notification.removeEventListener 'show', hideNotification
                    , timeout
                notification.addEventListener 'show', hideNotification
            return true

        autoHide = ->
            $rootScope.Settings['Client/NotificationCloseTimeout'] > 0

        showErrorBar = (error) ->
            errorText.innerText = error.toString()
            errorBar.className = 'alert alert-danger'
            if autoHide()
                timeout = 2000
                if $rootScope?.Settings?['Client/NotificationCloseTimeout']?
                    timeout = $rootScope.Settings['Client/NotificationCloseTimeout']
                setTimeout ->
                    errorBar.className = 'alert alert-danger hide'
                , timeout

        notify = (error) ->
            done = false
            if $rootScope?.Settings?['Client/EnableDesktopNotification']
                if Notification?.permission is 'granted'
                    done = showDesktopNotification error
                if not done and Notification?.permission isnt 'denied'
                    Notification.requestPermission  ->
                        notify error
                    return
            else if not done and $rootScope?.Settings?['Client/EnableErrorBarNotification']
                showErrorBar error
            else
                console.error error

        errorHappened: (status, error) =>
            if status == 401
                window.location = '/'
                return
            notify error
            for callback in @errorListeners
                callback error
            return
]
