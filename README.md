[![Build Status](https://travis-ci.com/Parsely/AnalyticsSDK-iOS.svg?token=9KfLpysxdvyb5zeXEppg&branch=master)](https://travis-ci.com/Parsely/AnalyticsSDK-iOS)

# Parsely Tracking on iOS

This repository contains the code necessary to build and test the Parsely tracking framework for iOS. It also includes a basic sample iOS app that can be used to interactively experiment with Parsely tracking.

## XCode setup

    $ sudo gem install cocoapods
    $ pod install

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

In any file that uses Parsely Analytics functionality, include `import ParselyTracker`

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
