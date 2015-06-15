# ionic-parse-facebook-scaffold

## installation
```
git clone https://github.com/mixersoft/ionic-parse-facebook-scaffold.git [folder]
cd [folder]
ionic lib update
bower install
npm install 
# if you need to run as administrator, use `sudo npm install`


# install Cordova plugins from web
mkdir hooks   # why is this folder missing?
ionic plugin add cordova-plugin-console
ionic plugin add com.ionic.keyboard
ionic plugin add cordova-plugin-device
ionic plugin add cordova-plugin-media
ionic plugin add cordova-plugin-file
ionic plugin add https://github.com/phonegap-build/PushPlugin
ionic plugin add https://github.com/katzer/cordova-plugin-local-notifications
ionic plugin add https://git-wip-us.apache.org/repos/asf/cordova-plugin-inappbrowser
ionic plugin add https://github.com/driftyco/ionic-plugins-deploy


# add Cordova platforms
# note: this project has only been tested on iOS 
ionic platform add ios
```

## Compile/build project. 
The project uses coffeescript so you'll need to run `gulp` to 'compile' to javascript.
```
gulp
# gulp copy:more      # to copy `app/views/index.html` to www folder
# gulp coffee         # to update just coffeescript
```

## Upload app to ionic.io
```
ionic upload 
```


## Add your API Keys 
Add keys to app/js/services/KEYS.coffee
- parse:      https://www.parse.com/apps
- facebook:   https://developers.facebook.com/apps, choose 'Website' app
- ionic:      https://apps.ionic.io/apps
remember to run `gulp coffee` for javascript

## Configure FacebookConnect
follow instructions here: https://github.com/ccoenraets/OpenFB

## Configure Push Notifications



## Build and deploy for device
```
ionic build ios
ionic emulate

```


