import Nimble
@testable import ParselyAnalytics
import XCTest

class VideoTests: ParselyTestCase {

    let testVideoId: String = "videoId"
    let testUrl: String = "testurl"
    var testVideoKey: String {
        return "\(testUrl)::\(testVideoId)"
    }

    func testTrackPlay() {
        let videoManager = VideoManager(trackerInstance: parselyTestTracker)

        expect(videoManager.trackedVideos).to(beEmpty())

        videoManager.trackPlay(
            url: testUrl,
            urlref: testUrl,
            vId: testVideoId,
            duration: TimeInterval(10),
            metadata: nil,
            extra_data: nil,
            idsite: Parsely.testAPIKey
        )

        expect(videoManager.trackedVideos).to(haveCount(1))
    }

    func testTrackPause() {
        let videoManager = VideoManager(trackerInstance: parselyTestTracker)

        videoManager.trackPlay(
            url: testUrl,
            urlref: testUrl,
            vId: testVideoId,
            duration: TimeInterval(10),
            metadata: nil,
            extra_data: nil,
            idsite: Parsely.testAPIKey
        )

        videoManager.trackPause()

        expect(videoManager.trackedVideos).to(haveCount(1))
    }

    func testReset() {
        let videoManager = VideoManager(trackerInstance: parselyTestTracker)

        videoManager.trackPlay(
            url: testUrl,
            urlref: testUrl,
            vId: testVideoId,
            duration: TimeInterval(10),
            metadata: nil,
            extra_data: nil,
            idsite: Parsely.testAPIKey
        )

        videoManager.reset(url: testUrl, vId: testVideoId)

        expect(videoManager.samplerTimer).toNot(beNil())
        expect(videoManager.trackedVideos).to(beEmpty())
    }

    func testUpdateVideoEventArgs() throws {
        let videoManager = VideoManager(trackerInstance: parselyTestTracker)

        let testSectionFirst = "sectionname"
        let testSectionSecond = "adifferentsection"
        let firstTestMetadata = ParselyMetadata(
            canonical_url: testUrl,
            pub_date: Date(),
            title: "test",
            authors: nil,
            image_url: nil,
            section: testSectionFirst,
            tags: nil,
            duration: nil,
            page_type: nil
        )

        videoManager.trackPlay(
            url: testUrl,
            urlref: testUrl,
            vId: testVideoId,
            duration: TimeInterval(10),
            metadata: firstTestMetadata,
            extra_data: nil,
            idsite: Parsely.testAPIKey
        )

        let testTrackedVideo = try XCTUnwrap(videoManager.trackedVideos.values.first)
        let actualMetadata = try XCTUnwrap(testTrackedVideo.eventArgs["metadata"] as? ParselyMetadata)

        expect(actualMetadata.section).to(equal(testSectionFirst))

        let secondTestMetadata = ParselyMetadata(
            canonical_url: testUrl,
            pub_date: Date(),
            title: "test",
            authors: nil,
            image_url: nil,
            section: testSectionSecond,
            tags: nil,
            duration: nil,
            page_type: nil
        )

        videoManager.trackPlay(
            url: testUrl,
            urlref: testUrl,
            vId: testVideoId,
            duration: TimeInterval(10),
            metadata: secondTestMetadata,
            extra_data: nil,
            idsite: Parsely.testAPIKey
        )

        let secondTestTrackedVideo = try XCTUnwrap(videoManager.trackedVideos.values.first)
        let secondActualMetadata = try XCTUnwrap(secondTestTrackedVideo.eventArgs["metadata"] as? ParselyMetadata)

        expect(secondActualMetadata.section).to(equal(testSectionSecond))
    }

    func testSampleFn() {
        let videoManager = VideoManager(trackerInstance: parselyTestTracker)

        videoManager.trackPlay(
            url: testUrl,
            urlref: testUrl,
            vId: testVideoId,
            duration: TimeInterval(10),
            metadata: nil,
            extra_data: nil,
            idsite: Parsely.testAPIKey
        )

        expect(videoManager.sampleFn(key: self.testVideoKey)).to(beTrue())
    }

    func testSampleFnPaused() {
        let videoManager = VideoManager(trackerInstance: parselyTestTracker)

        videoManager.trackPlay(
            url: testUrl,
            urlref: testUrl,
            vId: testVideoId,
            duration: TimeInterval(10),
            metadata: nil,
            extra_data: nil,
            idsite: Parsely.testAPIKey
        )
        videoManager.trackPause()

        expect(videoManager.sampleFn(key: self.testVideoKey)).to(beFalse())
    }

    func testHeartbeatFn() {
        let videoManager = VideoManager(trackerInstance: parselyTestTracker)
        let dummyAccumulator = makeAccumulator(videoManager: videoManager, key: testVideoKey, url: testUrl)

        videoManager.trackPlay(
            url: testUrl,
            urlref: testUrl,
            vId: testVideoId,
            duration: TimeInterval(10),
            metadata: nil,
            extra_data: nil,
            idsite: Parsely.testAPIKey
        )
        videoManager.heartbeatFn(data: dummyAccumulator, enableHeartbeats: true)

        expect(self.parselyTestTracker.eventQueue.list).to(haveCount(2))
    }

    func testHeartbeatDoesNotCrashIfNoVideoHasBeenTracked() {
        let videoManager = VideoManager(trackerInstance: parselyTestTracker)
        let dummyAccumulator = makeAccumulator(videoManager: videoManager, key: testVideoKey, url: testUrl)

        // Send heart beat without tracking a play first...
        videoManager.heartbeatFn(data: dummyAccumulator, enableHeartbeats: true)

        // ...and verify that no crash has occurred by performing a simple assertion on the tracker state
        expect(self.parselyTestTracker.eventQueue.list).to(beEmpty())
    }
}

extension VideoTests {

    func makeAccumulator(videoManager: VideoManager, key: String, url: String) -> Accumulator {
        Accumulator(
            key: key,
            accumulatedTime: 0,
            totalTime: 0,
            firstSampleTime: Date(),
            lastSampleTime: Date(),
            lastPositiveSampleTime: Date(),
            heartbeatTimeout: 0,
            contentDuration: 0,
            isEngaged: false,
            eventArgs: videoManager.generateEventArgs(
                url: url,
                urlref: "",
                extra_data: nil,
                // Intresting: If this is defined as a default argument in the method signature, it won't compile.
                idsite: Parsely.testAPIKey
            ) as [String: Any]
        )
    }
}
