Changelog
=========

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
