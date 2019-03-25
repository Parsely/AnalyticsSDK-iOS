Contribution Guide
==================

Building the framework
----------------------

The iOS tracker SDK is distributed as a `.framework` file. How to build this file:

* Open this repository's toplevel `xcworkspace` file in XCode.
* Click the scheme indicator, directly right of the "stop" button in the upper left corner
* Select the `ParselyTracker` scheme and the "Generic iOS Device" target
* Click the play button to build the framework
* Click the XCode menu, then Preferences, then Locations
* Note the path labeled "Derived Data", navigate to this path in Finder
* Find the directory whose name includes `ParselyDemo`, navigate to `Build/Products/Debug-iphoneos` therein
* Find the `ParselyTracker.framework` file

Versioning
----------

The Parsely Analytics project adheres to the `semantic versioning specification`_. It uses version
numbers of the form `X.Y.Z` where X is the major version, Y is the minor version, and
Z is the patch version. Releases with different major versions indicate
changes to the public API.

Past versions of th Parsely Analytics SDK are maintained in git with tags. When patches or
private code changes are made to the latest version, it is sometimes desirable
to backport those changes to older versions. We like to avoid backporting changes
when possible, but sometimes it's necessary to continue supporting past versions.
In these cases, the changes should be applied on a branch from a checkout of the old
version. This new HEAD should be tagged with the appropriately incremented
version number, and the tag and branch should be pushed to github. After the release
has been created, the branch should be deleted so that only the tagged release remains.

.. _semantic versioning specification: http://semver.org/

Release Process
---------------

* Verify that all tests pass on master
* Add and commit updates to the `changelog`_
* Increment the `version`_ according to SemVer, commit and tag with the version string
* Push this change with `git push origin master --tags`
* `pod trunk push ParselyAnalytics.podspec`
* Use the GitHub `release UI`_ to create a new release
* Increment the `version`_ according to SemVer to the next development version.
  Commit and push this change, but don't make a new tag.

.. _changelog: https://github.com/Parsely/AnalyticsSDK-iOS/blob/master/CHANGES.rst
.. _version: https://github.com/Parsely/AnalyticsSDK-iOS/blob/3035f9ebb10b84053168f5dd2eae718246d43f44/ParselyAnalytics.podspec#L3
.. _release UI: https://github.com/Parsely/AnalyticsSDK-iOS/releases/new
