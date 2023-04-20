import XCTest
import os.log
@testable import ParselyAnalytics

class EngagedTimeTests: ParselyTestCase {
    var engagedTime: EngagedTime?
    let testUrl: String = "http://parsely-stuff.com"

    override func setUp() {
        super.setUp()
        engagedTime = EngagedTime(trackerInstance: parselyTestTracker)
    }

    func testHeartbeatFn() {
        let dummyEventArgs: Dictionary<String, Any> = engagedTime!.generateEventArgs(
            url: testUrl, urlref: "", extra_data: nil, idsite: Parsely.testAPIKey)
        let dummyAccumulator: Accumulator = Accumulator(key: "", accumulatedTime: 0, totalTime: 0,
                                                        firstSampleTime: Date(),
                                                        lastSampleTime: Date(), lastPositiveSampleTime: Date(),
                                                        heartbeatTimeout: 0, contentDuration: 0, isEngaged: false,
                                                        eventArgs: dummyEventArgs)
        engagedTime!.heartbeatFn(data: dummyAccumulator, enableHeartbeats: true)
        XCTAssertEqual(parselyTestTracker.eventQueue.length(), 1,
                       "A call to EngagedTime.heartbeatFn should add an event to eventQueue")
    }

    func testStartInteraction() {
        engagedTime!.startInteraction(url: testUrl, urlref: "", extra_data: nil,
                                      idsite: Parsely.testAPIKey)
        let internalAccumulators:Dictionary<String, Accumulator> = engagedTime!.accumulators
        let testUrlAccumulator: Accumulator = internalAccumulators[testUrl]!
        XCTAssert(testUrlAccumulator.isEngaged,
                  "After a call to EngagedTime.startInteraction, the internal accumulator for the engaged " +
                  "url should exist and its isEngaged flag should be set")
    }

    func testEndInteraction() {
        engagedTime!.startInteraction(url: testUrl, urlref: "", extra_data: nil,
                                      idsite: Parsely.testAPIKey)
        engagedTime!.endInteraction()
        let internalAccumulators:Dictionary<String, Accumulator> = engagedTime!.accumulators
        let testUrlAccumulator: Accumulator = internalAccumulators[testUrl]!
        XCTAssertFalse(testUrlAccumulator.isEngaged,
                       "After a call to EngagedTime.startInteraction followed by a call to " +
                       "EngagedTime.stopInteraction, the internal accumulator for the engaged " +
                       "url should exist and its isEngaged flag should be unset")
    }

    func testSampleFn() {
        engagedTime!.startInteraction(url: testUrl, urlref: "", extra_data: nil,
                                      idsite: Parsely.testAPIKey)
        let sampleResult: Bool = engagedTime!.sampleFn(key: testUrl)
        XCTAssert(sampleResult,
                  "After a call to EngagedTime.startInteraction, EngagedTime.sample should return true for the interacting key")
    }

    func testSampleFnPaused() {
        engagedTime!.startInteraction(url: testUrl, urlref: "", extra_data: nil,
                                      idsite: Parsely.testAPIKey)
        engagedTime!.endInteraction()
        let sampleResult: Bool = engagedTime!.sampleFn(key: testUrl)
        XCTAssertFalse(sampleResult,
                       "After a call to EngagedTime.startInteraction followed by a call to " +
                       "EngagedTime.stopInteraction, EngagedTime.sample should return false for the interacting key")
    }


    func testGlobalPause() {
        let parsely = makePareslyTracker()
        // This is call to configure required for the start-stop mechanism to work
        parsely.configure(siteId: Parsely.testAPIKey)

        let assertionTimeout:TimeInterval = TimeInterval(3)
        let acceptableDifference:TimeInterval = TimeInterval(0.2)

        parsely.startEngagement(url: testUrl, urlref: "", extraData: nil, siteId: Parsely.testAPIKey)
        // sleep for three seconds
        let expectation = self.expectation(description: "Sampling")
        Timer.scheduledTimer(withTimeInterval: assertionTimeout, repeats: false) { timer in
            expectation.fulfill()
        }
        waitForExpectations(timeout: assertionTimeout + acceptableDifference, handler: nil)
        // put application in background
        if #available(iOS 13.0, *) {
            NotificationCenter.default.post(name: UIScene.didEnterBackgroundNotification, object: nil)
        } else{
            NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        }
        let accumulatedTime:TimeInterval = parsely.track.engagedTime.accumulators[testUrl]!.accumulatedTime
        XCTAssert(accumulatedTime <= 3, "Engaged time should be less than or equal to 3 seconds but it was \(accumulatedTime)")

        // sleep for three more seconds
        let expectationTwo = self.expectation(description: "Sampling")
        Timer.scheduledTimer(withTimeInterval: assertionTimeout, repeats: false) { timer in
            expectationTwo.fulfill()
        }
        waitForExpectations(timeout: assertionTimeout + acceptableDifference, handler: nil)

        // wake up the application
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)

        // stop tracking engaged time
        parsely.stopEngagement()
        let accumulatedTimeSecond:TimeInterval = parsely.track.engagedTime.accumulators[testUrl]!.accumulatedTime
        XCTAssert(accumulatedTimeSecond == 0.0,
                    "The accumulated time should be zero and it was \(accumulatedTimeSecond)")

    }
}
