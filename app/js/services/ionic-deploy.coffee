'use strict'

###*
# @ngdoc factory
# @name ionicDeploy
# @description  methods for managing $ionicDeploy in PROD app deployment, but not DEV
# @author Michael Lin, Snaphappi Inc.
# 
###



angular
.module 'ionic.deploy', [ 
  'ionic.service.core'
  'ionic.service.deploy'
]
.factory 'ionicDeploy', [
  '$ionicDeploy'
  ($ionicDeploy)->
    self = {
      hasUpdate: null
      lastChecked: null
      progress:
        download: null
        extract: null
      check: ()->
        $ionicDeploy.check()
        .then (response)->
          console.log "$ionicDeploy.check(), hasUpdate=" + response
          self.hasUpdate = response
          self.lastChecked = new Date()
          return $ionicDeploy.load() if !response

          return $ionicDeploy.download().then ()->
              return $ionicDeploy.extract().then ()->
                  console.log "$ionicDeploy() loading deployed version"
                  $ionicDeploy.load()
                  return
                , (err)->
                  console.error "$ionicDeploy.extract(), Error="+JSON.stringify err
                  return
                , (progress)-> 
                  self.progress.extract = progress;
                  return

              return
            , (err)->
              console.error "$ionicDeploy.download(), Error="+JSON.stringify err
              return
            , (progress)-> 
              self.progress.download = progress;
              return

        .catch (err)->
          return if err=="Plugin not loaded"
          console.error "$ionicDeploy.check(), Error="+JSON.stringify err
          return

      }
    return self

  ]