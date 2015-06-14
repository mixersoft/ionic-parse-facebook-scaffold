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
  ($scope, $rootScope, $timeout, $ionicPlatform, $ionicScrollDelegate, deviceReady, appFacebook)->

    $scope.deviceReady.waitP().then (platform)->
      $scope.device = platform # deviceReady.device()
      return

    $scope.watch = {
      items : []
    }

    $scope.on = {
      getParseUser: ()->
        $scope.watch.console = ''
        resp = {
          parseUser: $rootScope.parseUser?.toJSON()
          user: $rootScope.user
        }
        $scope.watch.console = JSON.stringify resp, null, 2

      getFbProfile: ()->
        $scope.watch.console =''
        return appFacebook.getMeP()
        .then (resp)->
            $scope.watch.console = JSON.stringify resp, null, 2
            return
          , (err)->
            $scope.watch.console = JSON.stringify err, null, 2
            return


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

