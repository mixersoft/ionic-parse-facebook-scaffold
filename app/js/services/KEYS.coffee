'use strict'

###*
 # @ngdoc overview
 # @name auth
 # @description
 # # save app keys
 #
 # authentication
###

angular
.module('auth',[])
.constant 'auth.KEYS', {
  ionic:
    app_id: null    # from apps.ionic.view
    api_key: null
    b64_auth: null  # for $ionicPush
    # b64_auth == btoa(PRIVATE_KEY+":")

  parse:
    APP_ID : null
    JS_KEY : null
    REST_API_KEY : null

  facebook: # see https://developers.facebook.com/apps
    app_id: null
}