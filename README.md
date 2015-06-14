# Pluckie

# installation
```
git clone [repo] [folder]
# git clone -b scaffold --single-branch https://github.com/mixersoft/pluckie [folder]

cd [folder]
# git remote rename origin seed
ionic lib update
bower install
npm install

ionic plugin add cordova-plugin-console
ionic plugin add com.ionic.keyboard
ionic plugin add cordova-plugin-device


# see https://www.parse.com/docs/ios/guide#push-notifications
ionic plugin add cordova-plugin-media
ionic plugin add cordova-plugin-file
ionic plugin add https://github.com/phonegap-build/PushPlugin
ionic plugin add https://github.com/katzer/cordova-plugin-local-notifications


ionic platform add ios
gulp
ionic build ios
ionic emulate
```

for openFb
ionic add openfb
ionic plugin add https://git-wip-us.apache.org/repos/asf/cordova-plugin-inappbrowser
```

for $ionicDeploy
```
ionic plugin add https://github.com/driftyco/ionic-plugins-deploy
ionic add ionic-service-core
ionic add ionic-service-deploy
```

for $ionicPush
```
# ionic plugin add https://github.com/phonegap-build/PushPlugin
# ionic add ngCordova
# ionic add ionic-service-core
ionic add ionic-service-push
```


Plugin re-installs
```
# install from web
ionic plugin add cordova-plugin-console
ionic plugin add com.ionic.keyboard
ionic plugin add cordova-plugin-device
ionic plugin add cordova-plugin-media
ionic plugin add cordova-plugin-file
ionic plugin add https://github.com/phonegap-build/PushPlugin
ionic plugin add https://github.com/katzer/cordova-plugin-local-notifications
ionic plugin add https://git-wip-us.apache.org/repos/asf/cordova-plugin-inappbrowser
ionic plugin add https://github.com/driftyco/ionic-plugins-deploy


# install from project folder plugins
ionic plugin add plugins/cordova-plugin-console
ionic plugin add plugins/com.ionic.keyboard
ionic plugin add plugins/cordova-plugin-device
ionic plugin add plugins/cordova-plugin-media
ionic plugin add plugins/cordova-plugin-file
ionic plugin add plugins/com.phonegap.plugins.PushPlugin
ionic plugin add plugins/de.appplant.cordova.common.registerusernotificationsettings
ionic plugin add plugins/de.appplant.cordova.plugin.local-notification
ionic plugin add plugins/cordova-plugin-inappbrowser
ionic plugin add plugins/com.ionic.deploy
```

for snappi.nativeMessenger CameraRoll plugin
```
# ionic plugin rm com.snaphappi.native-messenger.Messenger; 
ionic plugin add plugins/CordovaNativeMessenger
```


# observations
