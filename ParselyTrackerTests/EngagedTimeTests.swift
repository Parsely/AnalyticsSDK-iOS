import XCTest
@testable import ParselyTracker

class EngagedTimeTests: ParselyTestCase {
    var engagedTime: EngagedTime?
    let testUrl: String = "http://parsely-stuff.com"
    
    override func setUp() {
        super.setUp()
        engagedTime = EngagedTime(trackerInstance: parselyTestTracker)
    }
    
    func testHeartbeatFn() {
        let dummyEventArgs: EventArgs = engagedTime!.generateEventArgs(
            url: testUrl, urlref: "", extra_data: nil, idsite: ParselyTestCase.testApikey)
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
                                      idsite: ParselyTestCase.testApikey)
        let internalAccumulators:Dictionary<String, Accumulator> = engagedTime!.accumulators
        let testUrlAccumulator: Accumulator = internalAccumulators[testUrl]!
        XCTAssert(testUrlAccumulator.isEngaged,
                  "After a call to EngagedTime.startInteraction, the internal accumulator for the engaged " +
                  "url should exist and its isEngaged flag should be set")
    }
    
    func testEndInteraction() {
        engagedTime!.startInteraction(url: testUrl, urlref: "", extra_data: nil,
                                      idsite: ParselyTestCase.testApikey)
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
                                      idsite: ParselyTestCase.testApikey)
        let sampleResult: Bool = engagedTime!.sampleFn(key: testUrl)
        XCTAssert(sampleResult,
                  "After a call to EngagedTime.startInteraction, EngagedTime.sample should return true for the interacting key")
    }
    
    func testSampleFnPaused() {
        engagedTime!.startInteraction(url: testUrl, urlref: "", extra_data: nil,
                                      idsite: ParselyTestCase.testApikey)
        engagedTime!.endInteraction()
        let sampleResult: Bool = engagedTime!.sampleFn(key: testUrl)
        XCTAssertFalse(sampleResult,
                       "After a call to EngagedTime.startInteraction followed by a call to " +
                       "EngagedTime.stopInteraction, EngagedTime.sample should return false for the interacting key")
    }
}
