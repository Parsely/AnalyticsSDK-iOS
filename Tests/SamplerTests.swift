import XCTest
@testable import ParselyAnalytics

class SamplerTests: ParselyTestCase {
    var samplerUnderTest: Sampler?
    let testKey: String = "thing"
    
    let extraData: Dictionary<String, String> = [
        "arbitraryParameter1": "testValue",
        "arbitraryParameter2": "testValue2"
    ]
    let testMetadata: ParselyMetadata = ParselyMetadata(
        canonical_url: "http://parsely-test.com", pub_date: Date.init(), title: "a title.", authors: ["Yogi Berra"],
        image_url: "http://parsely-test.com/image2", section: "Things my mother says", tags: ["tag1", "tag2"],
        duration: TimeInterval(100)
    )
    
    override func setUp() {
        super.setUp()
        samplerUnderTest = Sampler(trackerInstance: parselyTestTracker)
    }
    
    func testMultipleTrackedItemsInOneSampler() {
        let itemOne: String = "itemOne"
        let itemTwo: String = "itemTwo"
        samplerUnderTest!.trackKey(key: itemOne, contentDuration: nil, eventArgs: [:])
        samplerUnderTest!.trackKey(key: itemTwo, contentDuration: nil, eventArgs: [:])

        XCTAssert(samplerUnderTest!.accumulators[itemOne]!.key != samplerUnderTest!.accumulators[itemTwo]!.key,
                  "Sequential calls to trackKey with different keys should not clobber each other's accumulator data")
    }

    func testSampleFn() {
        let assertionTimeout:TimeInterval = TimeInterval(3)
        let acceptableDifference:TimeInterval = TimeInterval(0.2)
        
        samplerUnderTest!.trackKey(key: "sampler-test", contentDuration: nil, eventArgs: [:])
        
        let expectation = self.expectation(description: "Sampling")
        Timer.scheduledTimer(withTimeInterval: assertionTimeout, repeats: false) { timer in
            expectation.fulfill()
        }
        waitForExpectations(timeout: assertionTimeout + acceptableDifference, handler: nil)
        
        let accumulatedTime:TimeInterval = samplerUnderTest!.accumulators["sampler-test"]!.totalTime
        XCTAssert(accumulatedTime >= assertionTimeout - acceptableDifference,
                  "The sampler should accumulate time constantly after a call to trackKey")
    }

    func testBackoff() {
        let initialInterval = samplerUnderTest!.heartbeatInterval
        // Ensure value matches magic number from production code
        XCTAssertEqual(initialInterval, TimeInterval(10.5))
        
        // Track an event, then make the test runner wait for the heartbeat interval plus some extra
        // time to account for runtime delays.
        samplerUnderTest!.trackKey(key: "sampler-test", contentDuration: nil, eventArgs: [:])
        
        let expectation = self.expectation(description: "Wait for heartbeat")
        let heartbeatDeliveryInterval = initialInterval + TimeInterval(3)
        Timer.scheduledTimer(withTimeInterval: heartbeatDeliveryInterval, repeats: false) { timer in
            expectation.fulfill()
        }
        // Wait slightly longer to reduce the race between waiting for the `expectation` to be
        // fulfilled and the fulfillment.
        waitForExpectations(timeout: heartbeatDeliveryInterval + 0.01, handler: nil)
        
        let actualUpdatedInterval = samplerUnderTest!.heartbeatInterval
        // This value depends on heartbeatInterval, and two magic numbers in the implementation.
        // We use the output value instead of writing out the math that computes it because doing
        // so would amount to duplicating the logic under test in the test itself.
        let expectedUpdatedInterval = TimeInterval(13.65)

        // We've seen a version of this test with strict `XCTAssertEqual` being flaky and
        // failing with a tracked interval a few hundredth of a second different from the expected
        // value of 13.65.
        //
        // See for example https://github.com/Automattic/AnalyticsSDK-iOS/pull/6#issuecomment-1508327314
        //
        // In the context of a backoff implementation it seems acceptable to account for a few
        // hundredth of a second difference between the expected interval and the recorded one.
        XCTAssertEqual(
            actualUpdatedInterval,
            expectedUpdatedInterval,
            accuracy: 0.04,
            "Heartbeat interval should increase by the expected amount after a single heartbeat"
        )
    }

    func testDistinctTrackedItems() {
        let sampler1 = Sampler(trackerInstance: parselyTestTracker)
        let sampler2 = Sampler(trackerInstance: parselyTestTracker)
        sampler1.trackKey(key: testKey, contentDuration: nil, eventArgs: [:])
        sampler2.trackKey(key: testKey, contentDuration: nil, eventArgs: [:])
        sampler1.dropKey(key: testKey)
        XCTAssert(sampler2.accumulators[testKey] != nil,
                  "A Sampler instance should not be affected by dropKey calls on another Sampler instance")
    }
    
    func testDropKey() {
        samplerUnderTest!.trackKey(key: testKey, contentDuration: nil, eventArgs: [:])
        samplerUnderTest!.dropKey(key: testKey)
        XCTAssertNil(samplerUnderTest!.accumulators[testKey],
                     "After a call to Sampler.dropKey, the accumulator for the droppesd key should not exist")
    }
    
    func testGenerateEventArgs() {
        let testUrl: String = "http://parselystuff.com"
        let eventArgs: Dictionary<String, Any> = samplerUnderTest!.generateEventArgs(
            url: testUrl, urlref: testUrl, metadata: testMetadata, extra_data: extraData,
            idsite: ParselyTestCase.testApikey)
        XCTAssertEqual(eventArgs["url"] as! String, testUrl, "The url returned in the result of Sampler.generateEventArgs " +
                       "should match the one passed to the call")
        XCTAssertEqual(eventArgs["urlref"] as! String, testUrl, "The urlref returned in the result of " +
                       "Sampler.generateEventArgs should match the one passed to the call")
        XCTAssertEqual(eventArgs["idsite"] as! String, ParselyTestCase.testApikey,
                       "The idsite returned in the result of Sampler.generateEventArgs should match the one passed to the call")
        let actualExtraData: Dictionary<String, Any> = eventArgs["extra_data"] as! Dictionary<String, Any>
        for (key, value) in extraData {
            XCTAssertEqual(actualExtraData[key]! as! String, value,
                           "The result of Sampler.generateEventArgs should have correct values passed via extra_data")
        }
        let actualMetadata: ParselyMetadata = eventArgs["metadata"] as! ParselyMetadata
        let expectedMetadata: Dictionary<String, Any> = testMetadata.toDict()
        let result: Bool = NSDictionary(dictionary: actualMetadata.toDict()).isEqual(to: expectedMetadata)
        XCTAssert(result, "The metadata field of the result of Sampler.generateEventArgs should be a dict representation " +
                          "of the given metadata")
    }
    
    func testPause() {
        samplerUnderTest!.pause()
        XCTAssertNil(samplerUnderTest!.samplerTimer,
                     "After a call to Sampler.pause(), Sampler.samplerTimer should be nil")
    }
    
    func testResume() {
        samplerUnderTest!.pause()
        samplerUnderTest!.resume()
        XCTAssertNil(samplerUnderTest!.samplerTimer,
                     "After a call to Sampler.resume() without sampling having started, Sampler.samplerTimer should be nil")
    }
    
    func testResumeHasStartedSampling() {
        samplerUnderTest!.pause()
        samplerUnderTest!.hasStartedSampling = true
        samplerUnderTest!.resume()
        XCTAssertNotNil(samplerUnderTest!.samplerTimer,
                        "After a call to Sampler.resume() without sampling having started, Sampler.samplerTimer should be nil")
    }
    
    func testPauseStopsCounting() {
        let assertionTimeout:TimeInterval = TimeInterval(3)
        let acceptableDifference:TimeInterval = TimeInterval(0.2)
        
        samplerUnderTest!.trackKey(key: "sampler-test", contentDuration: nil, eventArgs: [:])
        
        let expectation = self.expectation(description: "Sampling")
        Timer.scheduledTimer(withTimeInterval: assertionTimeout, repeats: false) { timer in
            expectation.fulfill()
        }
        waitForExpectations(timeout: assertionTimeout + acceptableDifference, handler: nil)
        
        let accumulatedTime:TimeInterval = samplerUnderTest!.accumulators["sampler-test"]!.accumulatedTime
        samplerUnderTest!.pause()
        XCTAssert(accumulatedTime >= assertionTimeout - acceptableDifference,
                  "The sampler should accumulate time constantly after a call to trackKey")
        
        let secondExpectation = self.expectation(description: "Paused sampling")
        Timer.scheduledTimer(withTimeInterval: assertionTimeout, repeats: false) { timer in
            secondExpectation.fulfill()
        }
        waitForExpectations(timeout: assertionTimeout + acceptableDifference, handler: nil)
        
        let secondAccumulatedTime: TimeInterval = samplerUnderTest!.accumulators["sampler-test"]!.accumulatedTime
        XCTAssert(secondAccumulatedTime <= assertionTimeout, "AccumulatedTime was \(secondAccumulatedTime)")
    }
}
