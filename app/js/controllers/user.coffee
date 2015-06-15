'use strict'

###*
# @ngdoc function
# @name appProfile
# @description methods for managing Parse.User attributes
# @author Michael Lin, Snaphappi Inc.
###
angular.module('starter')
.factory 'appProfile', [
  '$rootScope', '$q', 'appParse', 'ngFB', 'exportDebug'
  ($rootScope, $q, appParse, ngFB, exportDebug)->

    _username = {
      regExp : /^[a-z0-9_!\@\#\$\%\^\&\*.-]{3,20}$/

      dirty : ()->
        return $rootScope.user['username'] != self.userModel()['username']

      isValid: (ev)->
        return self.userModel()['username']? && _username.regExp.test(self.userModel()['username'].toLowerCase())

      ngClassValidIcon: ()->
        return 'hide' if !_username.dirty() || !self.userModel()['username']
        if _username.isValid(self.userModel()['username'].toLowerCase())
          # TODO: also check with parse?
          return 'ion-ios-checkmark balanced' 
        else 
          return 'ion-ios-close assertive'
    }

    _password = {
      regExp : /^[A-Za-z0-9_-]{8,20}$/
      'passwordAgainModel': null
      showPasswordAgain : ''

      dirty : ()->
        return $rootScope.user['password'] != self.userModel()['password']

      edit: ()-> 
        # show password confirm popup before edit
        _password.showPasswordAgain = true
        self.userModel()['password'] = ''

      isValid: (field='password')-> # validate password or oldPassword
        return self.userModel()[field]? && _password.regExp.test(self.userModel()[field])

      isConfirmed: ()-> 
        return _password.isValid() && _password['passwordAgainModel'] == self.userModel()['password']
      
      ngClassValidIcon: (field='password')->
        return 'hide' if !_password.dirty()
        if _password.isValid(field)
          return 'ion-ios-checkmark balanced' 
        else 
          return 'ion-ios-close assertive'
      ngClassConfirmedIcon: ()->
        return 'hide' if !_password.dirty() || !_password['passwordAgainModel']
        if _password.isConfirmed() 
          return 'ion-ios-checkmark balanced' 
        else 
          return 'ion-ios-close assertive'
    }

    _email = {
      dirty : ()->
        return $rootScope.user['email'] != self.userModel()['email']
      
      regExp : /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/

      isValid: (ev)->
        return self.userModel()['email']? && _email.regExp.test(self.userModel()['email'])
      isVerified: ()->
        return self.userModel()['emailVerified']
      ngClassEmailIcon: ()->
        if _email.dirty() 
          if _email.isValid()
            return 'ion-ios-checkmark balanced' 
          else 
            return 'ion-ios-close assertive'
        else 
          if _email.isVerified()
            return 'ion-ios-checkmark balanced'
          else if self.userModel()['email']?
            return 'ion-flag assertive'
          else 
            return 'hide'

    }

    self = {
      isAnonymous: appParse.isAnonymousUser

      _userModel : {}
      userModel: (user)->
        # copy of $rootScope.parseUser fields for possible update/edit
        return self._userModel if `user==null`
        return self._userModel = user

      dirty : ()->
        keys = ['username', 'password', 'email']
        return _.isEqual( _.pick( $rootScope.user, keys ),  _.pick( self.userModel(), keys )) == false

      signOut: ()->
        appParse.logoutSession()
        self.userModel( {} )
        return 

      signInP: (userCred)->
        return appParse.loginP(userCred).then (o)->
            self.userModel( _.pick $rootScope.user, ['username', 'password', 'email', 'emailVerified'] )
            return o
          , (err)->
            self.userModel( {} )
            $q.reject(err)

      submitP: ()->
        updateKeys = []
        _.each ['username', 'password', 'email'], (key)->
          updateKeys.push(key) if self[key].dirty()           # if key == 'email'  # managed by parse
          return
        if !self.isAnonymous()
          # confirm current password before change
          updateKeys.push('currentPassword')
        return appParse.saveSessionUserP(updateKeys, self.userModel() ).then (userObj)->
            self.userModel( _.pick $rootScope.user, ['username', 'password', 'email', 'emailVerified'] )
            return userObj

      ngClassSubmit : ()->
        if (self.email.dirty() && self.email.isValid()) || (self.password.dirty() && self.password.isConfirmed() )
          enabled = true 
        else 
          enabled = false
        return if enabled then 'button-balanced' else 'button-energized disabled'

      ngClassSignin : ()->
        if self.userModel()['username'] && self.userModel()['password']           
          enabled = true 
        else 
          enabled = false
        return if enabled then 'button-balanced' else 'button-energized disabled'

      displaySessionUsername: ()->
        return "anonymous" if self.isAnonymous()
        return $rootScope.parseUser.get('username')

      username: _username
      password: _password
      email: _email
      errorMessage: ''

    }
    exportDebug.appProfile = self
    return self

]


###*
 # @ngdoc function
 # @name UserCtrl
 # @description controller for User/Profile actions
###
angular.module('starter')
.controller 'UserCtrl', [
  '$scope', '$rootScope', '$q', '$timeout'
  '$ionicHistory', '$ionicPopup', '$ionicNavBarDelegate', 
  'appParse', 'appProfile', 'appFacebook', 'ngFB'
  ($scope, $rootScope, $q, $timeout, $ionicHistory, $ionicPopup, $ionicNavBarDelegate, appParse, appProfile, appFacebook, ngFB) ->
    
    $scope.appProfile = appProfile
    $scope.deviceReady.waitP().then (platform)->
      $scope.device = platform # deviceReady.device()
      return

    $scope.watch = {
      isNullUser: ()->
        return $rootScope.parseUser == null
      isLinkedUser: ()->
        # it is possible to be a linkedUser but NOT connected
        return $rootScope.parseUser?.get('authData')?
      isConnectedUser: ()->
        # Parse.Session.createdWith records authProvider, BUT
        # does not get updated on disconnect
        return false if $scope.watch.isLinkedUser() == false
        # isConnected set in appFacebook: getMeP(), checkLoginP(), disconnectP()
        return $rootScope.user['isConnected']

      viewName: ()->
        return 'sign-in' if $rootScope.$state.includes('app.profile.sign-in')
        
        switch appParse.authProvider()
          when 'anonymous'
            return 'anonymous'
          when 'password'
            return 'parse'
          when 'facebook', 'twitter'
            return appParse.authProvider() if $scope.watch.isConnectedUser()
            # connect Token expired, ask to renew
            return appParse.authProvider() if $scope.watch.isLinkedUser()
            return 'anonymous'
        
        return 'anonymous' if appProfile.isAnonymous()
        return 'facebook' if $rootScope.user['fbProfile']? 
        return 'parse'

        
      showAdvanced: false # show advanced settings
      'fbProfile': null   # initially set in AppCtrl
    }

    $rootScope.$watch 'user.fbProfile', (newV, oldV)->
      $scope.watch['fbProfile'] = newV
      authData = $rootScope.parseUser?.get('authData')
      return $scope.watch['authData'] = null if _.isEmpty authData

      authProvider = _.keys( authData )[0]
      $scope.watch['authData'] = {
          'authProvider': authProvider
          'id': authData[authProvider]['id']
          'expirationDate': authData[authProvider]['expiration_date']
        }
      return
          

    $scope.on = {
      toggleShowAdvanced: ()->
        $scope.watch.showAdvanced = !$scope.watch.showAdvanced

      useAsGuest: ()->
        return if $rootScope.parseUser != null
        return appParse.checkSessionUserP(null, 'create').then ()->
          $rootScope.$state.reload()


      signOut : (ev)->
        ev.preventDefault() 

        # add confirm.
        switch appParse.authProvider()  
          when 'anonymous'
            confirm = "Are you sure you want to sign-out?\nYou do not have a password and cannot recover this account."
            resp = window.confirm(confirm)
            return false if !resp 
          when 'facebook','twitter'
            if $rootScope.user['unlinked'] == true
              confirm = "Are you sure you want to sign-out?\nYou have unlinked this account and have not set a password."

        if confirm?
          resp = window.confirm(confirm)
          return false if !resp 
            
        appProfile.signOut()
        appFacebook.disconnectP()
        $rootScope.$broadcast 'user:sign-out' 
        $rootScope.$state.transitionTo('app.profile.sign-in')
        return     
    
      signIn : (ev)->
        ev.preventDefault()
        return if appProfile.ngClassSignin().indexOf('disabled') > -1
        
        userCred = _.pick appProfile.userModel(), ['username', 'password']
        return appProfile.signInP(userCred).then ()->

            appProfile.errorMessage = ''
            target = 'app.profile'
            $ionicHistory.nextViewOptions({
              historyRoot: true
            })
            $rootScope.$state.transitionTo(target)  
          , (error)->
            $rootScope.$state.transitionTo('app.profile.sign-in')
            switch error.code 
              when 101
                message = "The Username and Password combination was not found. Please try again."
              else
                message = "Sign-in unsucessful. Please try again."
            appProfile.errorMessage = message
            return 
          .then ()->
            # refresh everything
            $rootScope.$broadcast 'user:sign-in' 
            return


      submit : (ev)->
        ev.preventDefault()
        return if appProfile.ngClassSubmit().indexOf('disabled') > -1

        # either update or CREATE
        isCreate = if _.isEmpty($rootScope.parseUser) then true else false
        return appProfile.submitP()
        .then ()->
            appProfile.errorMessage = ''
            if isCreate
              $ionicHistory.nextViewOptions({
                historyRoot: true
              })
              target = 'app.profile'
              $rootScope.$state.transitionTo(target)
            # else stay on app.settings.profile page
        , (error)->
          appProfile.password.passwordAgainModel = ''
          switch error.code 
            when 202, 203
              message = "That Username/Email was already taken. Please try again."
            when 301
              appProfile.userModel _.pick $rootScope.user, ['username', 'password', 'email', 'emailVerified']
              message = "You don't have permission to make those changes."
            else
              message = "Sign-up unsucessful. Please try again."
          appProfile.errorMessage = message
          return 
        return 

      fbConnectP: ()->
        $scope.showLoading()
        return appFacebook.loginP()
        .then (status)->
          # loginP() calls getMeP()
          # updated fbProfile in $rootScope.user['fbProfile']
          $rootScope.$broadcast 'user:sign-in'
          $rootScope.$state.transitionTo('app.profile')
          return 'done'
        .catch (err)->
          $rootScope.$broadcast 'user:sign-out'
          console.warn 'fbLoginP', err
          return 
        .finally ()->
          $scope.hideLoading()

      fbDisconnectP: ()->
        $scope.showLoading()
        return appFacebook.disconnectP().then ()->
          $scope.hideLoading()
          return


      getFbUserP:(id = null, fields)->
        default_profile_fields = 'id,name,first_name,last_name,email,gender,location,locale,link,timezone,verified,picture,cover'
        options = {
          path : '/' + (id || 'me')
          params: 
            'fields': fields || default_profile_fields
        }
        return ngFB.api(options)

      getFbFriendsP:()-> # friends ALSO using the app
        return ngFB.api({ 
          path: '/'+ $scope.watch.fbProfile.id + '/friends' 
          limit: 50
        }).then (resp)->
          $scope.friends = resp.data
          console.log 'getFbFriendsP', resp  
        .catch (err)->
          console.error 'getFbFriendsP', err

      getFbMutualFriendsP:()->
        return ngFB.api({ 
          path: '/'+ $scope.watch.fbProfile.id +'/mutualfriends' 
          limit: 50
        }).then (resp)->
          $scope.fbUser = resp
          console.log 'getFbMutualFriendsP', resp  
        .catch (err)->
          console.error 'getFbMutualFriendsP', err

    }

    $rootScope.$on '$stateChangeSuccess', (event, toState, toParams, fromState, fromParams)->
      return if /^app.settings/.test(toState.name) == false
      switch toState.name
        when 'app.profile.profile'
          appProfile.userModel _.pick $rootScope.user, ['username', 'password', 'email', 'emailVerified']
        when 'app.profile.sign-in'
          appProfile.userModel({})
      return
 


    $scope.$on '$ionicView.loaded', ()->
      appProfile.userModel({})
      return

    $scope.$on '$ionicView.beforeEnter', ()->
      appProfile.errorMessage = ''
      return

    $scope.$on '$ionicView.enter', ()->
      return if $rootScope.$state.includes('app.profile.sign-in')
      appProfile.userModel _.pick $rootScope.user, ['username', 'password', 'email', 'emailVerified']
      return

    $scope.$on '$ionicView.leave', ()->
      # cached view becomes in-active 
      return 

]  