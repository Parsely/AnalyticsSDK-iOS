[![Build Status](https://travis-ci.com/Parsely/AnalyticsSDK-iOS.svg?token=9KfLpysxdvyb5zeXEppg&branch=master)](https://travis-ci.com/Parsely/AnalyticsSDK-iOS)

# Parsely Tracking on iOS

This repository contains the code necessary to build and test the Parsely tracking framework for iOS. It also includes a basic sample iOS app that can be used to interactively experiment with Parsely tracking.

The `ParselyAnalytics` SDK is available via [CocoaPods](https://cocoapods.org/pods/ParselyAnalytics).

## Including ParselyAnalytics in a project

First, set up a local CocoaPods environment if you haven't already:

    $ sudo gem install cocoapods

Then add the following to your the project's Podfile:

    pod 'ParselyAnalytics'

Then, run `pod install` to install `ParselyAnalytics` as a dependency.

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
