# cordova-swift-inappbrowser
Cordova Plugin for Nostr In App Browser

In order to test and launch follow these steps:

1. Create a separate folder "TestPlugin"
2. Clone this repository into the folder
3. Clone https://github.com/nostrband/inappbrowser-test into the same folder
4. Launch terminal and open the inappbrowser-test folder
5. Enter the following commands:
   
    sudo cordova platform add ios
   
    sudo cordova plugin add cordova-plugin-add-swift-support --save
   
    sudo cordova plugin add ../InAppBrowser
   
7. Open the "TestPlugin" folder preferences and give yourself right to read and write in it, also apply it to all enclosed items.
8. Open HelloCordova.xcworkspace folder in inappbrowser-test/platforms/ios/
9. In project settings change swift version to 5.0 and iOS deployment version to >=13.0
10. Build and run.

