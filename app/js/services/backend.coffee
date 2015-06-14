'use strict'

###*
# @ngdoc factory
# @name appParse
# @description  methods for accessing parse javascript SDK
# @author Michael Lin, Snaphappi Inc.
# 
###

### login notes:
  parseLogin vs linkLogin w/authData

  parseLogin
    parseUser.get('authData')==null
    parseUser.password
    parseUser.emailVerified READ_ONLY

  linkedLogin:
    parseUser.get('authData')?
    parseUser.username is random string
    parseUser.username = linkedUser.name, BUT owner can update
    parseUser.email == linkedUser.email
    parseUser.linkedId = linkedUser.id  # not sure what happens to parseUser when unlinked
    ignore parseUser.password
    ignore parseUser.emailVerfied

    check Session.get('createdWith').authProvider = [anonymous,password,facebook,twitter]
    you can recover an unlinked account, only for Parse.User.current(), i.e. not logged out

    BUG: 
      for browser, linkUserP() returns a 60 day expiration, regardless of authData
      for device, authData expiration is put into UserObj.authData correctly, 
        but Parse.User.current().get('authData') returns an expired token

    BUG: 
      for device, inAppBrowser only appears first time, can't re-connect a 2nd time.

###

angular
.module 'parse.backend', ['auth']
.factory 'restApi', [
  '$http', 'auth.KEYS'
  ($http, KEYS)->
    parseHeaders_GET = {
        'X-Parse-Application-Id': KEYS.APP_ID,
        'X-Parse-REST-API-Key':KEYS.REST_API_KEY,
    }
    parseHeaders_SET = _.defaults { 'Content-Type':'application/json' }, parseHeaders_GET
    self = {
        getAll: (className)->
            return $http.get('https://api.parse.com/1/classes/' + className, {
              headers: parseHeaders_GET
            })
        get: (className, id)->
            return $http.get('https://api.parse.com/1/classes/' + className + '/' + id, {
              headers: parseHeaders_GET
            })
        create: (className, data)->
            return $http.post('https://api.parse.com/1/classes/' + className, data, {
              headers: parseHeaders_SET
            })
        edit: (className, id, data)->
            return $http.put('https://api.parse.com/1/classes/' + className + '/' + id, data, {
              headers: parseHeaders_SET
            });
        delete: (className, id)->
            return $http.delete('https://api.parse.com/1/classes/' + className + '/' + id, {
              headers: parseHeaders_SET
            })
    }
    return self
]

.factory 'appParse', [
  '$q', '$timeout', '$http', '$rootScope', 'deviceReady', 'auth.KEYS', 
  'exportDebug'
  ($q, $timeout, $http, $rootScope, deviceReady, KEYS, exportDebug)->

    parseClass = {
      BacklogObj : Parse.Object.extend('BacklogObj')
    }

    ANON_PREFIX = {
      username: 'anonymous-'
      password: 'password-'
    }

    ANON_USER = {
      id: null
      username: null
      password: null
      email: null
      emailVerified: false
      tosAgree: false
      rememberMe: false
      isRegistered: false       
    }


    self = {
      _authProvider : null
      authProvider : (value)->
        self._authProvider = value if `value!=null`
        return self._authProvider

      authProviderP: ()->
        return Parse.Session.current()
        .then (session)->
          return self.authProvider( session.get('createdWith').authProvider )

      isAnonymousUser: ()->
        # should really check self.authProviderP() 
        if self.authProvider()?
          return true if self.authProvider() == 'anonymous'
          return false
        return true if _.isEmpty $rootScope.parseUser
        return false if $rootScope.parseUser.get('authData')
        return true if $rootScope.parseUser.get('username').indexOf(ANON_PREFIX.username) == 0
        # return true if $rootScope.parseUser.get('username') == 'browser'
        return false

      mergeSessionUser: (anonUser={})->
        anonUser = _.extend _.clone(ANON_USER), anonUser
        # merge from cookie into $rootScope.user
        $rootScope.parseUser = Parse.User.current()
        return anonUser if !($rootScope.parseUser instanceof Parse.Object)

        isRegistered = !self.isAnonymousUser()
        return anonUser if !isRegistered
        
        userCred = _.pick( $rootScope.parseUser.toJSON(), [
          'username', 'role', 
          'email', 'emailVerified', 
          'tosAgree', 'rememberMe'
        ] )
        userCred.password = 'HIDDEN'
        userCred.tosAgree = !!userCred.tosAgree # checkbox:ng-model expects a boolean
        userCred.isRegistered = self.isAnonymousUser()
        return _.extend anonUser, userCred

      signUpP: (userCred)->
        user = new Parse.User();
        user.set("username", userCred.username.toLowerCase())
        user.set("password", userCred.password)
        user.set("email", userCred.email) 
        return user.signUp().then (user)->
            promise = self.authProviderP()
            return $rootScope.parseUser = Parse.User.current()
          , (user, error)->
            $rootScope.parseUser = null
            $rootScope.user.username = ''
            $rootScope.user.password = ''
            $rootScope.user.email = ''
            console.warn "parse User.signUp error, msg=" + JSON.stringify error
            return $q.reject(error)

      ###
      # parseUser login only, authProvider='password'
      # @params userCred object, keys {username:, password:}
      #     or array of keys
      ###
      loginP: (userCred, signOutOnErr=true)->
        userCred = _.pick userCred, ['username', 'password']
        return deviceReady.waitP().then ()->
          return Parse.User.logIn( userCred.username.trim().toLowerCase(), userCred.password )
        .then (user)->  
            promise = self.authProviderP()
            $rootScope.parseUser = Parse.User.current()
            $rootScope.user = self.mergeSessionUser($rootScope.user)
            return user
        , (error)->
            if signOutOnErr
              $rootScope.parseUser = null
              $rootScope.$broadcast 'user:sign-out'
              console.warn "User login error. msg=" + JSON.stringify error
            $q.reject(error)

      signUpOrLoginFromAuthDataP: (authData, cb)->
        options = {
          method: 'POST'
          url: "https://api.parse.com/1/users"
          headers: 
            'X-Parse-Application-Id': KEYS.parse.APP_ID
            'X-Parse-REST-API-Key': KEYS.parse.REST_API_KEY
            'Content-Type': 'application/json'
          data: {authData: authData}
        }

        return deviceReady.waitP()
        .then ()->
          if deviceReady.device().isDevice
            # for device Only or also Browser?
            return Parse._getInstallationId()
            .then (installationId)->
              options.headers['X-Parse-Installation-Id'] = installationId
              return options

          else
            return options
        .then (options)->
          return $http( options )
        .then (resp)->
          switch resp.status
            when 200,201
              sessionToken = resp.data.sessionToken
              return Parse.User.become(sessionToken)
              .then (user)->
                $rootScope.parseUser = Parse.User.current()
                $rootScope.user = self.mergeSessionUser($rootScope.user)
                return resp
            else
              return $q.reject (resp)
        .then (resp)->
          # import FB attrs, see appFacebook._patchUserFieldsP(fbUser)
          switch resp.status
            when 200
              console.log ">> Parse LOGIN from linkedUser", [resp.data, authData]
            when 201 # created new Parse.User from linked Account
              console.log ">> Parse user CREATED from linkedUser", [resp.data, authData]
              if _.isFunction cb
                return cb( resp ).then ()->
                  return resp 
          return resp

      logoutSession: (anonUser)->
        Parse.User.logOut()
        $rootScope.parseUser = Parse.User.current()
        $rootScope.user = ANON_USER
        return

      anonSignUpP: (seed)->
        _uniqueId = (length=8) ->
          id = ""
          id += Math.random().toString(36).substr(2) while id.length < length
          id.substr 0, length
        seed = _uniqueId(8) if !seed
        anon = {
          username: ANON_PREFIX.username + seed
          password: ANON_PREFIX.password + seed
        }
        return self.signUpP(anon)
        .then (userObj)->
            return userObj
          , (userCred, error)->
            console.warn "parseUser anonSignUpP() FAILED, userCred=" + JSON.stringify userCred 
            return $q.reject( error )

      linkUserP: (authData)->
        parseUser = Parse.User.current()
        return $q.reject('linkUserP error: Parse.User not signed in ') if !parseUser

        options = {
          method: 'PUT'
          url: "https://api.parse.com/1/users/" + parseUser.id
          headers: 
            'X-Parse-Application-Id': KEYS.parse.APP_ID
            'X-Parse-REST-API-Key': KEYS.parse.REST_API_KEY
            'X-Parse-Session-Token': parseUser.getSessionToken()
            'Content-Type': 'application/json'
          params: null
          data: {authData: authData}
        }
        return $http( options ).then (resp)->
          console.log ">> Parse user LINKED to linkedUser", [resp.data, authData]
          return $q.reject (resp) if resp.statusText != 'OK' 
          return parseUser




      # confirm userCred or create anonymous user if Parse.User.current()==null
      checkSessionUserP: (userCred, createAnonUser=true)-> 
        if userCred # confirm userCred
          authPromise = self.loginP(userCred, false).then null, (err)->
              return $q.reject({
                  message: "userCred invalid"
                  code: 301
                })
        else if $rootScope.parseUser
          authPromise = $q.when($rootScope.parseUser)
        else 
          authPromise = $q.reject()

        if createAnonUser
          authPromise = authPromise.then (o)->
              return o
            , (error)->
              return self.anonSignUpP()

        return authPromise


      saveSessionUserP : (updateKeys, userCred)->
        # update or create
        if _.isEmpty($rootScope.parseUser)
          # create
          promise = self.signUpP(userCred)
        else if self.isAnonymousUser()
          promise = $q.when()
        else  # verify userCred before updating user profile
          reverify = {
            username: userCred['username']
            password: userCred['currentPassword']
          }
          promise = self.checkSessionUserP(reverify, false)

        promise = promise.then ()->
            # userCred should be valid, continue with update
            _.each updateKeys, (key)->
                return if key == 'currentPassword'
                if key=='username'
                  userCred['username'] = userCred['username'].trim().toLowerCase()
                $rootScope.parseUser.set(key, userCred[key])
                return
            return $rootScope.parseUser.save().then ()->
                return $rootScope.user = self.mergeSessionUser($rootScope.user)
              , (error)->
                $rootScope.parseUser = null
                $rootScope.user.username = ''
                $rootScope.user.password = ''
                $rootScope.user.email = ''
                console.warn "parse User.save error, msg=" + JSON.stringify error
                return $q.reject(error)
          .then ()->
              $rootScope.parseUser = Parse.User.current()
              return $q.when($rootScope.parseUser)
            , (err)->
              return $q.reject(err) # end of line

      updateUserProfileP : (options)->
        keys = ['tosAgree', 'rememberMe']
        options = _.pick options, keys
        return $q.when() if _.isEmpty options
        return deviceReady.waitP().then ()->
          return self.checkSessionUserP(null, true)
        .then ()->
            return $rootScope.parseUser.save(options)
          , (err)->
            return err



      ###
      # THESE METHODS ARE UNTESTED
      ###

      uploadPhotoMetaP: (workorderObj, photo)->
        return $q.reject("uploadPhotoMetaP: photo is empty") if !photo
        # upload photo meta BEFORE file upload from native uploader
        # photo.src == 'queued'
        return deviceReady.waitP().then self.checkSessionUserP(null, false)
        .then ()-> 
          attrsForParse = [
            'dateTaken', 'originalWidth', 'originalHeight', 
            'rating', 'favorite', 'caption', 'hidden'
            'exif', 'orientation', 'location'
            "mediaType",  "mediaSubTypes", "burstIdentifier", "burstSelectionTypes", "representsBurst",
          ]
          extendedAttrs = _.pick photo, attrsForParse
          # console.log extendedAttrs

          parseData = _.extend {
                # assetId: photo.UUID  # deprecate
                UUID: photo.UUID
                owner: $rootScope.parseUser
                deviceId: deviceReady.device().id
                src: "queued"
            }
            , extendedAttrs # , classDefaults

          photoObj = new parseClass.PhotoObj parseData , {initClass: false }
          # set default ACL, owner:rw, Curator:rw
          photoACL = new Parse.ACL(parseData.owner)
          photoACL.setRoleReadAccess('Curator', true)
          photoACL.setRoleWriteAccess('Curator', true)
          photoObj.setACL (photoACL)
          return photoObj.save()
        .then (o)->
            # console.log "photoObj.save() complete: " + JSON.stringify o.attributes 
            return 
          , (err)->
            console.warn "ERROR: uploadPhotoMetaP photoObj.save(), err=" + JSON.stringify err
            return $q.reject(err)

      uploadPhotoFileP : (options, dataURL)->
        # called by parseUploader, _uploadNext()
        # upload file then update PhotoObj photo.src, does not know workorder
        # return parseFile = { UUID:, url(): }
        return deviceReady.waitP().then self.checkSessionUserP(null, false) 
          .then ()->
            if deviceReady.device().isBrowser
              return $q.reject( {
                UUID: UUID
                message: "error: file upload not available from browser"
              }) 
          .then ()->
            photo = {
              UUID: options.UUID
              filename: options.filename
              data: dataURL
            }
            # photo.UUID, photo.data = dataURL
            return self.uploadFileP(photo.data, photo)
          .catch (error)->
            skipErrorFile = {
              UUID: error.UUID
              url: ()-> return error.message
            }
            switch error.message
              when "error: Base64 encoding failed", "Base64 encoding failed"
                return $q.when skipErrorFile
              when "error: UUID not found in CameraRoll", "Not found!"
                return $q.when skipErrorFile
              else 
                throw error     

      # 'parse' uploader only, requires DataURLs
      uploadFileP : (base64src, photo)->
        if /^data:image/.test(base64src)
          # expecting this prefix: 'data:image/jpg;base64,' + rawBase64
          mimeType = base64src[10..20]
          ext = 'jpg' if (/jpg|jpeg/i.test(mimeType))   
          ext = 'png' if (/png/i.test(mimeType)) 
          filename = photo.filename || photo.UUID.replace('/','_') + '.' + ext

          console.log "\n\n >>> Parse file save, filename=" + filename
          console.log "\n\n >>> Parse file save, dataURL=" + base64src[0..50]

          # get mimeType, then strip off mimeType, as necessary
          base64src = base64src.split(',')[1] 
        else 
          ext = 'jpg' # just assume

        # save DataURL as image file on Parse
        parseFile = new Parse.File(filename, {
            base64: base64src
          })
        return parseFile.save()

    }
    exportDebug.appParse = self
    return self
]


###
#
# @ngdoc factory
# @name appFacebook
# @description 
# methods for accessing openFB lib, se https://github.com/ccoenraets/OpenFB
# 
###
angular
.module( 'parse.backend')
.factory 'appFacebook', [ 
  '$q'
  '$rootScope'
  'exportDebug'
  'appParse', 'ngFB'
  ($q, $rootScope, exportDebug, appParse, ngFB)->

    $rootScope.$on 'user:sign-out', ()->
      self.disconnectP()
      return

    self = {
     
      LINK_EXPIRATION_DAYS: 60

      _findParseUserByLinkedIdP : (fbId)->
          return $q.when( rootScope.parseUser ) if $rootScope.parseUser

          userQ = new Parse.Query(Parse.User)
          userQ.equalTo('linkedId', fbId)
          return userQ.first().then (resp)->
            return $q.reject('Parse User not found') if _.isEmpty resp
            return resp

      _getAuthData: (fbUser, fbLogin)->
        return authData = {facebook:null} if fbUser==false
        expireTime = 1000 * 3600 * 24 * self.LINK_EXPIRATION_DAYS + Date.now()
        return authData = {
          facebook: 
            id: fbUser.id
            access_token: fbLogin.authResponse.accessToken
            # authData.expiration sets to +60 days regardless of what we put here
            expiration_date: new Date(expireTime).toJSON()  

        } 

      _patchUserFieldsP : (fbUser)->
        parseUser = Parse.User.current()
        updateFields = {
          'name': fbUser.name
          'linkedId': fbUser.id     # save for admin recovery
          'face': fbUser.picture.data.url
        }
        if parseUser.get('emailVerified') != true
          updateFields['email'] = fbUser.email
        return parseUser.save( updateFields)


      checkLoginP: (user)->
        user = $rootScope.user if `user==null`
        return ngFB.getLoginStatus()
        .then (resp)->
          console.log "checkLoginP",  resp
          $rootScope.user['isConnected'] = $rootScope.user['fbProfile']?
          return resp.status if resp.status == 'connected'

          $rootScope.user['fbProfile'] = null
          $rootScope.user['isConnected'] = $rootScope.user['fbProfile']?
          return $q.reject('fbUser not connected')
          
      loginP: (privileges)->
        default_access = 'public_profile,email,user_friends'
        privileges = default_access if !privileges
        fbLogin = null

        return ngFB.login({ scope: privileges })
        .then (resp)->
          fbLogin = resp
          if resp.status != 'connected'
            $rootScope.localStorage['fbProfile'] = $rootScope.user['fbProfile'] = null
            $rootScope.user['isConnected'] = $rootScope.user['fbProfile']?
            console.warn "Facebook login failed, resp=", resp
            return $q.reject(resp)

          # FbLogin sucessful
          console.log 'FB connected=', resp.status
          return self.getMeP()
          .then (fbUser)->
            # Parse login or create NEW parseUser
            if $rootScope.parseUser == null
              # create anon user and link with FbUser
              authData = self._getAuthData(fbUser, fbLogin)
              return appParse.signUpOrLoginFromAuthDataP( authData )
              .then ()->
                return self._patchUserFieldsP(fbUser)


            if $rootScope.parseUser?
              # link Parse.User & FbUser: replace any prior authData
              authData = self._getAuthData(fbUser, fbLogin)
              return appParse.linkUserP( authData )
              .then ()->
                return self._patchUserFieldsP(fbUser)

        .then ()->
          promise = appParse.authProviderP()
          return fbLogin.status
              
      disconnectP: ()->
        # disconnect revokes the Fb sessionToken. 
        # calls to getMeP() should fail with "Invalid OAuth access token."
        return ngFB.logout().then ()->
          $rootScope.localStorage['fbProfile'] = $rootScope.user['fbProfile'] = null
          $rootScope.user['isConnected'] = $rootScope.user['fbProfile']?
          return ngFB.getLoginStatus().then (resp)->
            console.log "disconnnect status=",resp

      unlinkP: ()->
        # resets parseUser.authData
        return appParse.authProviderP()
        .then (authProvider)->
          if authProvider != 'facebook'
            return $q.reject('ERROR: unlinkP() session not linked from Facebook') 

          # reset the parseUser.authData field
          authData = self._getAuthData(false)
          return appParse.linkUserP(authData)
        .then (resp)->
          return self.disconnectP()
        .then ()->
          return $rootScope.parseUser.save({
              'face':null
              'name':null
              'email':null # unique key
            })
        .then ()->
          # manually set to 'password' this is only valid to next logout
          promise = appParse.authProvider('password')
          $rootScope.user['unlinked'] = true
          # Parse.User.logOut();
          $rootScope.$state.reload()
          console.log "done"

      getMeP: (fields)->
        default_profile_fields = 'id,name,first_name,last_name,email,gender,location,locale,link,timezone,verified,picture,cover'
        options = {
          path : '/me'
          params: 
            'fields': fields || default_profile_fields
        }
        return ngFB.api(options)
        .then (resp)->
          if appParse.isAnonymousUser()
            _.extend $rootScope['user'], {
              username: resp.name
              email: resp.email
              emailVerified: resp.email?
            }
          $rootScope.localStorage['fbProfile'] = $rootScope.user['fbProfile'] = resp
          $rootScope.user['isConnected'] = $rootScope.user['fbProfile']?
          console.log 'getFbUserP', resp 
          return resp 
        .catch (err)->
          console.error 'getFbUserP', err
          $rootScope.user['isConnected'] = false
          return $q.reject(err)

      getPermissions: ()->
        options = {
          path : '/me/permissions'
        }
        return ngFB.api(options)
        .then (resp)->
          return resp.data      

    }
    exportDebug.appFacebook = self
    return self

]

# # test cloudCode with js debugger
window.cloud = {  }




