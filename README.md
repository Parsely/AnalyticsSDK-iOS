[![Build Status](https://travis-ci.com/Parsely/AnalyticsSDK-iOS.svg?token=9KfLpysxdvyb5zeXEppg&branch=master)](https://travis-ci.com/Parsely/AnalyticsSDK-iOS)

# Parsely Tracking on iOS

This repository contains the code necessary to build and test the Parsely tracking framework for iOS. It also includes a basic sample iOS app that can be used to interactively experiment with Parsely tracking. Full API documentation is available [here](https://www.parse.ly/help/integration/ios-sdk).

The `ParselyAnalytics` SDK is available via [CocoaPods](https://cocoapods.org/pods/ParselyAnalytics).

## Including ParselyAnalytics in a project

First, set up a local CocoaPods environment if you haven't already:

    $ sudo gem install cocoapods

Then add the following to your the project's Podfile:

    pod 'ParselyAnalytics'

Then, run `pod install` to install `ParselyAnalytics` as a dependency.

## Required: configure your site IDs

The SDK does not hardcode a collection endpoint. Parse.ly decides which endpoint your site's
data goes to, and the SDK learns it at build time.

**1. Declare every site ID your app tracks** in `parsely-apikeys.json` at your project root:

```json
{ "apikeys": ["example.com", "example.co.uk"] }
```

This must be exhaustive. It needs the site ID you pass to `configure(siteId:)` *and* every
site ID you ever pass as the `siteId:` argument of a tracking method.

**2. Add the build phase.** In Xcode, select your app target, then Build Phases, then add a
New Run Script Phase. Drag it above Copy Bundle Resources and set:

```
Script:       bash "${SRCROOT}/Scripts/parsely-bake-hosts.sh"
Input Files:  $(SRCROOT)/parsely-apikeys.json
Output Files: $(SRCROOT)/ParselyHosts.json
```

CocoaPods users get this phase automatically and can skip this step.

**3. Commit both files.** You maintain `parsely-apikeys.json`; `ParselyHosts.json` is
generated — do not edit it by hand.

Your build fails if a declared site ID is not one Parse.ly recognises. If Parse.ly is
temporarily unreachable but the generated file already covers every declared site ID, the
build warns and continues rather than failing on an outage.

### If you skip the build phase

The build phase is how a misconfiguration is caught. Without it nothing fails at build time
and **the SDK sends no analytics at all** — an app with no `ParselyHosts.json` in its bundle
logs an error from `configure` and drops every event. Events for a site ID missing from
`ParselyHosts.json` are likewise dropped rather than sent to the wrong endpoint.

## Using the tracker

In any file that uses Parsely Analytics functionality, include `import ParselyAnalytics`

At app startup, initialize the `Parsely` singleton. A good place to do this might be the top-level application delegate:

```swift
var parsely: Parsely?

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    self.parsely = Parsely.sharedInstance

    // optionally call configure to set an API Key for all requests
    self.parsely.configure(siteId: "example.com")

    // other app initialization
    return true
}
```

Once you've done this, you can call tracking methods on `self.parsely`:

```swift
self.parsely.trackPageView(url: "http://mysite.com/story1")
self.parsely.startEngagement(url: "http://mysite.com/story2")
self.parsely.stopEngagement()
```

## Design Notes

To conserve battery usage and network bandwidth, the SDK will batch pixel requests as they are made,
and flush them periodically. Each pixel retains its creation timestamp regardless of when it was sent.
Upon app shutdown, or when the app is backgrounded, it will flush whatever pixels are currently in the queue.
