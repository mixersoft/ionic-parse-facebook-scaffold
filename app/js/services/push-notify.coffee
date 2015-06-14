'use strict'

###*
 # @ngdoc service
 # @name parsePush
 # @description wrapper for pushNotification plugin, register installation with push server on PARSE
 # handle push notification events:  adds badges, notifications to iOS notification panel
 # for ParseJs Push configuration details, see:
 #    https://www.parse.com/docs/ios/guide#push-notifications
 #    https://www.parse.com/tutorials/ios-push-notifications
 # @author Michael Lin, Snaphappi Inc.
###

angular
.module 'parse.push', [
  'ionic', 
  'snappi.util'
  'parse.backend'
  'auth'
]
.factory( 'parsePush', [ 
  '$rootScope', '$location', '$q', '$log', '$http'
  '$cordovaPush', '$cordovaMedia'
  'notifyService'
  'auth.KEYS', 'deviceReady'
  
  ($rootScope, $location, $q, $log, $http, $cordovaPush, $cordovaMedia, notify, KEYS, deviceReady)->

    notifyPayloads = {
      'example':
        aps:
          alert: 
            title: 'Your Order is Ready for Review'
            body: "You have 91 TopPicks from this order. Have a look now!"
          badge: null # new picks
          sound: 'default'
          'content-available': 1
        target: 
          state: 'app.orders.detail'
          params: null
       
    }



    $rootScope.$on '$cordovaPush:notificationReceived', (event, notification)->
      console.log "notification received, JSON="+JSON.stringify notification
      $log.debug( '$cordovaPush:notificationReceived', notification )
      if ionic.Platform.isAndroid()
        self.handleAndroid( notification )
      else if ionic.Platform.isIOS()
        self.handleIOS( notification )
      return

    _localStorageDevice = null 

    self = {
      # check existing Parse Installation object
      ###
      # @param $localStorageDevice object, place to check for/save existing Parse installation
      #   keys; ['objectId', 'deviceType', 'installationId', 'owner', 'username']
      #   NOTE: should be saved to $localStorage['device']
      ###
      initialize: ($localStorageDevice)->
        return self if deviceReady.device().isBrowser == true

        _localStorageDevice = $localStorageDevice
        self.isReady = true
        console.log "pushNotificationPluginSvc initialized", $localStorageDevice

        # debug only
        self['messages'] = {}
        _.each _.keys( notifyPayloads ), (key)->
          self['messages'][key] = JSON.stringify notifyPayloads[key]
          return

        return self

      registerP: ()->
        return $q.when() if deviceReady.device().isBrowser == true

        if !self.isReady
          $log.warn("WARNING: attempted to register device before plugin intialization.") 
          return $q.reject("pushNotify plugin not initialized")

        return Parse._getInstallationId()
        .then (installationId)->
          if _localStorageDevice?['pushInstall']?
            isOK = true
            isOK = isOK && $rootScope.parseUser?.id && _localStorageDevice['pushInstall'].ownerId == $rootScope.parseUser.id 
            isOK = isOK && _localStorageDevice['pushInstall'].deviceId == deviceReady.device().id
            isOK = isOK && _localStorageDevice['pushInstall'].installationId == installationId
            if isOK
              console.log("pushInstall OK")
              return $q.when('done')
          #   else
          #     console.log "localStorage pushInstall=" + JSON.stringify _localStorageDevice['pushInstall']
          #     console.log "compare to:" + JSON.stringify [ $rootScope.parseUser.id, deviceReady.device().id, installationId ]
          else
            console.log "_localStorageDevice['pushInstall'] is EMPTY"

          if ionic.Platform.isAndroid()
            config = {
                "senderID": "YOUR_GCM_PROJECT_ID" #  // REPLACE THIS WITH YOURS FROM GCM CONSOLE - also in the project URL like: https://console.developers.google.com/project/434205989073
            }
          else if ionic.Platform.isIOS()
            config = {
                "badge": "true",
                "sound": "true",
                "alert": "true"
            }
          return $cordovaPush.register(config)
        .then (result)->
            # $log.debug("Register success " + result)
            if ionic.Platform.isIOS()
              self.storeDeviceTokenP {
                  type: 'ios'
                  deviceToken: result
                } 
            else if ionic.Platform.isAndroid()
              # ** NOTE: Android regid result comes back in the pushNotificationReceived
              angular.noop()
            return true
          , (err)->
            self.isReady = false
            console.log 'ERROR pushNotify.register(), err=' + JSON.stringify err
            return $q.reject("pushNotify $cordovaPush register error")


      handleIOS: (notification)->
        # The app was already open but we'll still show the alert 
        # and sound the tone received this way. If you didn't check
        # for foreground here it would make a sound twice, once when 
        # received in background and upon opening it from clicking
        # the notification when this code runs (weird).
        # $log.debug "handleIOS()", notification

        # looks like: Object
        #   body: "We have your order and are ready for photos. Visit the Uploader to get started."
        #   foreground: "1"
        #   sound: "default"
        #   target: "app.uploader"
        #   title: "Ready for Upload"
        if notification.foreground == '1'
          if notification.sound
            media = $cordovaMedia.newMedia(notification.sound).then ()->
                media.play()
                return
              , (err)->
                $log.error "Play media error", err

          if notification.badge
            $cordovaPush.setBadgeNumber(notification.badge).then (result)->
                $log.debug "Set badge success", result
                return
              , (err)->
                $log.error "Set badge error", err
        else 
          # sound, badge should be set in background by notification Center
          angular.noop()

        msg = {
          target : notification.target
        }
        if notification.body?
          msg['title'] = notification.title
          msg['message'] = notification.body
        else 
          msg['message'] = notification.alert
        notify.message msg,'info', 10000

        return if !notification.target

        # handle state transition
        if notification.target.state?
          $rootScope.$state.transitionTo( notification.target.state, notification.target.params ) 
        else
          $location.path(notification.target)  
        return       

      handleAndroid: (notification)->
        # // ** NOTE: ** You could add code for when app is in foreground or not, or coming from coldstart here too
        # //             via the console fields as shown.
        console.log("In foreground " + notification.foreground  + " Coldstart " + notification.coldstart);
        if notification.event == "registered"
          self.storeDeviceTokenP {
                  type: 'android'
                  deviceToken: result
                } 
        else if notification.event == "message"
          notify.message notification.message
          $log.debug 'handleAndroid', notification
        else if notification.event == "error"
          notify.message notification.message, 'error'
          $log.error 'Error: handleAndroid', notification
        return

      storeDeviceTokenP: (options)->
        throw "storeDeviceTokenP(): Error invalid options" if `options==null`
        return Parse._getInstallationId()
        .then (installationId)->

          postData = {
            "deviceId": deviceReady.device().id
            "deviceType": options.type,
            "deviceToken": options.deviceToken,
            "installationId" : installationId,
            "channels": [""] 
          }

          if $rootScope.parseUser?
            postData["owner"] = $rootScope.parseUser
            postData["ownerId"] = $rootScope.parseUser.id
            postData["username"] = $rootScope.parseUser.get('username')
            postData["active"] = true # active installation, for multiple users on same device
            # TODO: beforeSave set active=false for installationId==installationId
          else 
            postData["owner"] = null
            postData["ownerId"] = null
            postData["username"] = 'guest'
            postData["active"] = true # active installation, for multiple users on same device


          # TODO: move to otgParse?
          xhrOptions = {
            url: "https://api.parse.com/1/installations",
            method: "POST",
            data: postData,
            headers:  
              "X-Parse-Application-Id": KEYS.parse.APP_ID,
              "X-Parse-REST-API-Key": KEYS.parse.REST_API_KEY,
              "Content-Type": "application/json"
          }
          return $http(xhrOptions)
        .then (data, status)->
            _localStorageDevice['pushInstall'] = _.pick data, ['objectId', 'deviceType', 'deviceId', 'installationId', 'ownerId', 'username']
            console.log "Parse installation saved, data=" + JSON.stringify _localStorageDevice['pushInstall']
            return data
          , (data, status)->
            console.log "Error: saving Parse installation" + JSON.stringify([data, status]) 
            return $q.reject("pushNotify register error saving to Parse")


    }
    return self


  ])



###
  # push notification
    curl -X POST \
    -H "X-Parse-Application-Id: cS8RqblszHpy6GJLAuqbyQF7Lya0UIsbcxO8yKrI" \
    -H "X-Parse-REST-API-Key: 3n5AwFGDO1n0YLEa1zLQfHwrFGpTnQUSZoRrFoD9" \
    -H "Content-Type: application/json" \
    -d '{
      "channels":[
        "Curator"
      ],
      "data": {
        "aps" : {
          "alert": { 
            "title": "Watch out!", 
            "body": "A new Workorder was just created" 
          }, 
          "badge": 1, 
          "sound": "default", 
          "content-available": 1 
        },
        "target": "app.workorders.open" 
      }
    }' \
    https://api.parse.com/1/push;

  curl -X POST \
  -H "X-Parse-Application-Id: cS8RqblszHpy6GJLAuqbyQF7Lya0UIsbcxO8yKrI" \
  -H "X-Parse-REST-API-Key: 3n5AwFGDO1n0YLEa1zLQfHwrFGpTnQUSZoRrFoD9" \
  -H "Content-Type: application/json" \
  -d '{
    "where": {
      "ownerId": "Y72OwE1xzA"
    },
    "data": {
      "aps" : {
        "alert": { 
          "title": "Watch out!", 
          "body": "A new Workorder was just created" 
        }, 
        "badge": 1, 
        "sound": "default", 
        "content-available": 1 
      },
      "target": "app.workorders.open" 
    }
  }' \
  https://api.parse.com/1/push;

###