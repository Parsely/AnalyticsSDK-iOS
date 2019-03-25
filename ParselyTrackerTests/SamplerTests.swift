import XCTest
@testable import ParselyTracker

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
        let expectedBackoffMultiplier = 1.25
        let expectedUpdatedInterval = initialInterval * expectedBackoffMultiplier
        let assertionTimeout:TimeInterval = initialInterval + TimeInterval(2)
        
        samplerUnderTest!.trackKey(key: "sampler-test", contentDuration: nil, eventArgs: [:])
        
        let expectation = self.expectation(description: "Wait for heartbeat")
        Timer.scheduledTimer(withTimeInterval: assertionTimeout, repeats: false) { timer in
            expectation.fulfill()
        }
        waitForExpectations(timeout: assertionTimeout + 1, handler: nil)
        
        let actualUpdatedInterval = samplerUnderTest!.heartbeatInterval
        XCTAssertEqual(actualUpdatedInterval, expectedUpdatedInterval,
                  "Heartbeat interval should increase by the expected amount after a single heartbeat")
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
}
