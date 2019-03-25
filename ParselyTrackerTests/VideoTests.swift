import XCTest
@testable import ParselyTracker

class VideoTests: ParselyTestCase {
    let testVideoId: String = "videoId"
    let testUrl: String = "testurl"
    var videoManager: VideoManager?
    
    override func setUp() {
        super.setUp()
        videoManager = VideoManager(trackerInstance: parselyTestTracker)
    }
    
    func testTrackPlay() {
        XCTAssertEqual(videoManager!.trackedVideos.count, 0,
                       "videoManager.accumulators should be empty before calling trackPlay")
        videoManager!.trackPlay(url: testUrl, urlref: testUrl, vId: testVideoId, duration: TimeInterval(10),
                                metadata: nil, extra_data: nil, idsite: ParselyTestCase.testApikey)
        XCTAssertEqual(videoManager!.trackedVideos.count, 1,
                       "A call to trackPlay should populate videoManager.accumulators with one object")
    }
    
    func testTrackPause() {
        videoManager!.trackPlay(url: testUrl, urlref: testUrl, vId: testVideoId, duration: TimeInterval(10),
                                metadata: nil, extra_data: nil, idsite: ParselyTestCase.testApikey)
        videoManager!.trackPause()
        XCTAssertEqual(videoManager!.trackedVideos.count, 1,
                       "A call to trackPause should not remove an accumulator from videoManager.accumulators")
    }
    
    func testReset() {
        videoManager!.trackPlay(url: testUrl, urlref: testUrl, vId: testVideoId, duration: TimeInterval(10),
                                metadata: nil, extra_data: nil, idsite: ParselyTestCase.testApikey)
        videoManager!.pause()
        videoManager!.reset(url: testUrl, vId: testVideoId)
        XCTAssertNotNil(videoManager!.samplerTimer,
                        "videoReset should run successfully without the VideoManager instance being paused")
        XCTAssertEqual(videoManager!.trackedVideos.count, 0,
                       "A call to Parsely.track.videoManager.reset should remove a video from videoManager.trackedVideos")
    }
    func testUpdateVideoEventArgs() {
        let testSectionFirst: String = "sectionname"
        let testSectionSecond: String = "adifferentsection"
        let firstTestMetadata: ParselyMetadata = ParselyMetadata(canonical_url: testUrl, pub_date: Date(), title: "test",
                                                                 authors: nil, image_url: nil, section: testSectionFirst,
                                                                 tags: nil, duration: nil)
        videoManager!.trackPlay(url: testUrl, urlref: testUrl, vId: testVideoId, duration: TimeInterval(10),
                                metadata: firstTestMetadata, extra_data: nil, idsite: ParselyTestCase.testApikey)
        let testTrackedVideo: TrackedVideo = videoManager!.trackedVideos.values.first!
        let actualMetadata: ParselyMetadata = testTrackedVideo.eventArgs["metadata"]! as! ParselyMetadata
        XCTAssertEqual(actualMetadata.section, testSectionFirst,
                       "The section metadata stored for a video after a call to parsely.track.videoManager.trackPlay " +
                       "should match the section metadata passed to that call.")
        let secondTestMetadata: ParselyMetadata = ParselyMetadata(canonical_url: testUrl, pub_date: Date(), title: "test",
                                                                  authors: nil, image_url: nil, section: testSectionSecond,
                                                                  tags: nil, duration: nil)
        videoManager.trackPlay(url: testUrl, urlref: testUrl, vId: testVideoId, duration: TimeInterval(10),
                               metadata: secondTestMetadata, extra_data: nil, idsite: ParselyTestCase.testApikey)
        let secondTestTrackedVideo: TrackedVideo = videoManager.trackedVideos.values.first!
        let secondActualMetadata: ParselyMetadata = secondTestTrackedVideo.eventArgs["metadata"]! as! ParselyMetadata
        XCTAssertEqual(secondActualMetadata.section, testSectionSecond,
                       "The section metadata stored for a preexisting video after a call to parsely.track.videoManager.trackPlay " +
                       "should match the section metadata passed to that call.")
    }
    
    func testSampleFn() { XCTAssert(false, "not implemented") }
    func testHeartbeatFn() { XCTAssert(false, "not implemented") }
}
