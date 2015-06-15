'use strict'

###*
# @ngdoc overview
# @name starter
# @description  Main module of the application.
# @author Michael Lin, Snaphappi Inc.
###
angular
.module('starter', [
  'ionic',
  'ngCordova',
  'ngStorage'
  'partials'
  'snappi.util'
  'parse.backend'
  'parse.push'
  'ionic.deploy'
  # 'ionic.push'
  'auth'
  'ngOpenFB'
])

.constant( 'CHECK_DEPLOYED', false) # $ionicDeploy: check for updates on bootstrap

.value( 'exportDebug', {} ) # methods to exportDebug to JS global

.config [
  '$ionicAppProvider', 'auth.KEYS'
  ($ionicAppProvider, KEYS)->
    $ionicAppProvider.identify {
      app_id: KEYS.ionic.app_id
      api_key: KEYS.ionic.api_key
      dev_push: false
    }
    return
]
.config ['$ionicConfigProvider', 
  ($ionicConfigProvider)->
    return
]

.run [ 
  'ionicDeploy', '$rootScope'
  'CHECK_DEPLOYED', 'exportDebug' 
  (ionicDeploy, $rootScope, CHECK_DEPLOYED, exportDebug)->   
    $rootScope['deploy'] = ionicDeploy
    exportDebug['CHECK_DEPLOYED'] = CHECK_DEPLOYED

    exportDebug['ionicDeploy'] = ionicDeploy
    return if CHECK_DEPLOYED == false

    ionicDeploy.check()
    return
]

.run [
  '$ionicPlatform', '$rootScope', 'deviceReady', 'exportDebug', 'auth.KEYS', 'ngFB', 'appProfile'
  ($ionicPlatform, $rootScope, deviceReady, exportDebug, KEYS, ngFB, appProfile)->
    window.debug = exportDebug
    ngFB.init( { appId: KEYS.facebook.app_id })
    Parse.initialize( KEYS.parse.APP_ID, KEYS.parse.JS_KEY )
    $rootScope.parseUser = Parse.User.current()

    $ionicPlatform.ready ()->
      # Hide the accessory bar by default (remove this to show the accessory bar above the keyboard
      # for form inputs)
      cordova.plugins.Keyboard.hideKeyboardAccessoryBar(true) if window.cordova?.plugins.Keyboard
      # org.apache.cordova.statusbar required
      StatusBar.styleDefault() if window.StatusBar?
    return
]

.config [
  '$stateProvider', 
  '$urlRouterProvider', 
  ($stateProvider, $urlRouterProvider)-> 
  
    $stateProvider

    .state('app', {
      url: "/app",
      abstract: true,
      templateUrl: "/partials/templates/menu.html",
      controller: 'AppCtrl'
    })

    .state('app.home', {
      url: "/home",
      views: {
        'menuContent': {
          templateUrl: "/partials/home.html"
          controller: 'HomeCtrl'
        }
      }
    })

    .state('app.profile', {
      url: "/profile",
      views: {
        'menuContent': {
          templateUrl: "/partials/profile.html"
          controller: 'UserCtrl'
        }
      }
    })

    .state('app.profile.sign-in', {
      url: "/sign-in",
      # views: {
      #   'menuContent': {
      #     templateUrl: "/partials/templates/sign-in.html"
      #     controller: 'UserCtrl'
      #   }
      # }
    })


    # // if none of the above states are matched, use this as the fallback
    $urlRouterProvider.otherwise('/app/home');
]

.controller 'AppCtrl', [
  '$scope'
  '$rootScope' , '$state'
  '$timeout'
  '$ionicLoading'
  'deviceReady', 'exportDebug'
  '$localStorage'
  'parsePush'
  # 'ionicPush'
  'appProfile', 'appFacebook'
  ($scope, $rootScope, $state, $timeout, $ionicLoading, deviceReady, exportDebug, $localStorage, parsePush, appProfile, appFacebook)->
    $scope.deviceReady = deviceReady

    _.extend $rootScope, {
      $state : $state
      'user' : $rootScope.parseUser?.toJSON() || {}
      device : null # deviceReady.device(platform)
    }

    $scope.showLoading = (value = true, timeout=5000)-> 
      return $ionicLoading.hide() if !value
      $ionicLoading.show({
        template: '<ion-spinner class="spinner-light" icon="lines"></ion-spinner>'
        duration: timeout
      })
    $scope.hideLoading = (delay=0)->
      $timeout ()->
          $ionicLoading.hide();
        , delay 

    $scope.$on 'user:sign-in', (args)->
      console.log "$broadcast user:sign-in received"
      parsePush.registerP()

    $scope.$on 'user:sign-out', (args)->
      console.log "$broadcast user:sign-out received"
      parsePush.registerP() 

    $rootScope.localStorage = $localStorage
    if $rootScope.localStorage['device']?
      platform = $rootScope.localStorage['device']
      parsePush.initialize( platform )
      exportDebug['$platform'] = $rootScope['device'] = deviceReady.device(platform)
      console.log 'localStorage $platform=' + JSON.stringify exportDebug['$platform']
    else  
      # platform
      deviceReady.waitP().then (platform)->
          exportDebug['$platform'] = $rootScope['device'] = $rootScope.localStorage['device'] = platform
          console.log 'deviceReady $platform=' + JSON.stringify platform
          parsePush.initialize( platform ).registerP()
          return
        , (err)->
          console.warn err

    # load FB profile if available
    if !_.isEmpty $rootScope.user
      appFacebook.checkLoginP($rootScope.user)
      .then (status)->
        # only if logged in
        $rootScope.user['fbProfile'] = $localStorage['fbProfile'] 
        # update fbProfile
        return appFacebook.getMeP().then (resp)->
          return 'done'



    exportDebug['ls'] = $localStorage
    exportDebug['$root'] = $rootScope
    
    return


  ]
