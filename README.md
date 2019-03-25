[![Build Status](https://travis-ci.com/Parsely/AnalyticsSDK-iOS.svg?token=9KfLpysxdvyb5zeXEppg&branch=master)](https://travis-ci.com/Parsely/AnalyticsSDK-iOS)

# Parsely Tracking on iOS

This repository contains the code necessary to build and test the Parsely tracking framework for iOS. It also includes a basic sample iOS app that can be used to interactively experiment with Parsely tracking.

## XCode setup

    $ sudo gem install cocoapods
    $ pod install

## Building the framework

The iOS tracker SDK is distributed as a `.framework` file. How to build this file:

* Open this repository's toplevel `xcworkspace` file in XCode.
* Click the scheme indicator, directly right of the "stop" button in the upper left corner
* Select the `ParselyTracker` scheme and the "Generic iOS Device" target
* Click the play button to build the framework
* Click the XCode menu, then Preferences, then Locations
* Note the path labeled "Derived Data", navigate to this path in Finder
* Find the directory whose name includes `ParselyDemo`, navigate to `Build/Products/Debug-iphoneos` therein
* Find the `ParselyTracker.framework` file

## Including the framework in a project

* Click the toplevel XCode project file for your project in the Project Navigator
* In the "Build Phases" tab, expand "Link Binary with Libraries"
* Click the "+" sign and select the `ParselyTracker.framework` file
* Add the following dependencies to the project's Podfile:
```
pod 'SwiftyJSON', '~> 4.1.0'
pod 'SwiftHTTP', '~> 3.0.1'
pod 'ReachabilitySwift', '~> 4.3.0'
```

## Using the tracker

At app startup, initialize the `Parsely` singleton. A good place to do this might be the top-level application delegate:
```
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    self.parsely = Parsely.sharedInstance
    // other app initialization
    return true
}
```
Once you've done this, you can call tracking methods on `self.parsely`:
```
self.parsely.trackPageView(url: "http://mysite.com/story1")
self.parsely.startEngagement(url: "http://mysite.com/story2")
self.parsely.stopEngagement()
```
