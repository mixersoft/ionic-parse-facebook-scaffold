'use strict'

###*
# @ngdoc 
# @name HomeCtrl
# @description 
# @author Michael Lin, Snaphappi Inc.
# 
###


angular.module('starter')
.controller 'HomeCtrl', [
  '$scope'
  '$rootScope' 
  '$timeout'
  '$ionicPlatform'
  '$ionicScrollDelegate'
  'deviceReady'
  'appFacebook'
  'parsePush'
  ($scope, $rootScope, $timeout, $ionicPlatform, $ionicScrollDelegate, deviceReady, appFacebook, parsePush)->

    $scope.deviceReady.waitP().then (platform)->
      $scope.device = platform # deviceReady.device()
      return

    $scope.watch = {
      items : []
    }

    $scope.on = {
      getParseUser: ()->
        $scope.watch.console = 'loading Parse.User...'
        if `Parse.User.current()==null`
          $scope.watch.console = "Parse.User.current() == null"
          return
        return new Parse.Query(Parse.User).get($rootScope.parseUser.id)
        .then (user)->
            output = {
              parseUser: user.toJSON()
              user: $rootScope.user
            }
            $scope.watch.console = JSON.stringify output, null, 2
            $scope.$apply()
            return
          , (err)->
            $scope.watch.console = JSON.stringify err, null, 2
            return

      getFbProfile: ()->
        $scope.watch.console = 'loading Facebook profile...'
        return appFacebook.getMeP()
        .then (resp)->
            $scope.watch.console = JSON.stringify resp, null, 2
            return
          , (err)->
            $scope.watch.console = JSON.stringify err, null, 2
            return

      sendParsePush: ()->
        if `Parse.User.current()==null`
          $scope.watch.console = "Parse.User.current() == null"
          return
        $scope.watch.console = 'Sending in 2 secs - send App to background...'
        $timeout ()->
            $scope.watch.console = "SENDING..."
            parsePush.sayHelloP($rootScope.parseUser.id)
            .then (resp)->
                msg = {
                  result: 'SENT'
                  notification: resp
                }
                $scope.watch.console = JSON.stringify msg, null, 2
                return 
              , (err)->
                $scope.watch.console = JSON.stringify err, null, 2
                return
          , 2000



      sendIonicPush: ()->
        $scope.watch.console = 'ionic Push Notification not yet configured'


    }


    $scope.$on '$ionicView.loaded', ()->
      _init()
      console.log 'HomeCtrl $ionicView.loaded'
      # once per controller load, setup code for view
      return

    $scope.$on '$ionicView.beforeEnter', ()->
      return 

    $scope.$on '$ionicView.enter', ()->
      console.log 'HomeCtrl $ionicView.enter'
      
      return 


    $scope.$on '$ionicView.leave', ()-> 
      return 

    $scope.$on 'collection-repeat.changed', (ev, items)->
      $scope.watch.items = items
      $ionicScrollDelegate.$getByHandle('collection-repeat-wrap').resize()
      return



    _init = ()->
      items = $scope.watch.items
      $scope.$broadcast 'collection-repeat.changed', items
      
  ]

