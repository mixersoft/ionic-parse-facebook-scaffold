'use strict'

###*
# @ngdoc factory
# @name ionicPush
# @description methods for accessing $ionicPush
# @author Michael Lin, Snaphappi Inc.
# 
###

angular
.module 'ionic.push', ['auth']
.factory 'ionicPush', [
  '$rootScope'
  '$q'
  '$timeout'
  '$http'
  'auth.KEYS'
  '$ionicPush'
  ($rootScope, $q, $timeout, $http, KEYS, $ionicPush)->

    push = {
      headers: 
        "Authorization": "basic " + KEYS.ionic.b64_auth,
        "Content-Type": "application/json",
        "X-Ionic-Application-Id": KEYS.ionic.app_id

      registerP: (options, handleNotification)->
        # $rootScope.$on '$cordovaPush:tokenReceived', (event, data)->
        #   console.log('Ionic Push: Got token ', data.token, data.platform);
        #   $scope.user.token = data.token
        #   # save token to user
        #   $ionicUser.identify($scope.user).then (resp)->
        #     console.log('Updated user w/Token ' , $scope.user)

        config = _.defaults options, {
          canShowAlert: false,  # //Can pushes show an alert on your screen?
          canSetBadge: true,    # //Can pushes update app icon badges?
          canPlaySound: true,   # //Can notifications play a sound?
          canRunActionsOnWake: true, # //Can run actions outside the app,
        }
        config['onNotification'] = (notification)-> 
            # // Handle new push notifications here
            console.log "ionicPush onNotification, msg=", notification
            return handleNotification(notification) if handleNotification
            return true;
        
        return $ionicPush.register(config)

      pushP: (postData, delay=10)->
        dfd = $q.defer()
        $timeout ()->
            options = {
              method: 'POST'
              url: "https://push.ionic.io/api/v1/push"
              headers: push.headers
              params: null
              data: postData
            }
            console.log "push $http postData=", JSON.stringify(postData)[0..50]
            return $http( options )
            .then (resp)->
                return dfd.reject(resp.error) if resp.error?
                return dfd.resolve resp.data
              , (err)->
                console.warn "ionic.Push error: ", err
                return dfd.reject( err )
            return
          , delay
        return dfd.promise
        ###
        resp={
        }
        ###
    }





    window.push = push
    return push

]