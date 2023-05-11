Changelog
=========

Unreleased
----------

Changes
-------

_None_

Bugfixes
--------

_None_

0.2.2 (5-10-2023)

Changes
-------

* The library now uses a serial queue to process events [#76]
* Removed the dependency on SwiftyJSON [#76]

Bugfixes
--------

* Fixed the Swift Package Manager setup [#76]

0.2.1 (4-5-2023)

Changes
--------

* add support for Swift Package Manager (thanks @eddie-zhang)

0.2.0 (12-12-2022)

Bugfixes
--------

* Listen for correct background event in >= iOS 13
* Remove compatibility with < iOS 13

0.1.0 (4-20-2020)

Bugfixes
--------

* Remove Reachability as a dependency
* Fix 0 timestamps
* Adding compatibility with arm64 and newer Swift versions


0.0.10 (6-29-2020)
------------------

Bugfixes
--------

* Remove AlamoFire dependency in favor of stdlib HTTP request interface


0.0.9 (5-6-2020)
-----------------

Bugfixes
--------

* Force User-Agent header to be latin1 encoded

0.0.8 (3-24-2020)
-----------------

Bugfixes
--------

* Increment bugfix version

0.0.7 (3-24-2020)
-----------------

Bugfixes
--------

* Increment bugfix version

0.0.6 (2-18-2020)
-----------------

Bugfixes
--------

* Upgraded to a newer version of SwiftyJSON.
* Switched HTTP client from SwiftHTTP to Alamofire

0.0.5 (2-12-2020)
-----------------

Bugfixes
--------

* Switched to `UInt64` for timestamps to avoid crashes on 32-bit devices

0.0.4 (2-4-2020)
-----------------

Bugfixes
--------

* Added a `guard` to iteration over `accumulators`


0.0.3 (10-8-2019)
-----------------

Bugfixes
--------

* Fixed an incorrect unit on the `sts` event attribute


0.0.2 (10-7-2019)
-----------------

Bugfixes
--------

* Fixed metadata.pub_date formatting issue
* Added heartbeat backoff to engagement tracking

Miscellaneous
-------------

* Marked many functions as `internal` to facilitate testing
* Removed unused `reset` function

0.0.1 (3-25-2019)
-----------------

Miscellaneous
-------------

* Initial release
