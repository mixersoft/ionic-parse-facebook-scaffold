# ionic-parse-facebook-scaffold

## installation
```
git clone https://github.com/mixersoft/ionic-parse-facebook-scaffold.git [folder]
cd [folder]
ionic lib update
bower install
npm install 
# if you need to run as administrator, use `sudo npm install`

# To continue dev in a new git repo 
git remote rename origin scaffold 
git remote add origin [github repo]
git push -u origin master


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
Be sure to reset app_id="" in ionic.project to upload a *NEW* App
```
ionic upload 
```
WARNING: $ionicDeploy will load the uploaded/deployed image even when the app is launched
from xcode. To get the latest code from `ionic build ios` for testing, use the `cordova.js` hack in `index.html`. The ionic team is working on a proper solution.


## Add your API Keys 
Add keys to app/js/services/KEYS.coffee
- parse:      https://www.parse.com/apps
- facebook:   https://developers.facebook.com/apps, choose 'Website' app
- ionic:      https://apps.ionic.io/apps
remember to run `gulp coffee` for javascript

## Configure FacebookConnect
follow instructions here: https://github.com/ccoenraets/OpenFB

## Configure Push Notifications
for Parse.com Push Notifications, see: https://parse.com/tutorials/ios-push-notifications
*Make sure your BundleID matches the widget id in `config.xml`*

## Build and deploy for device
```
ionic build ios
ionic emulate

```




