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

        expect(videoManager.trackedVideos).to(beEmpty(), description: "videoManager.accumulators should be empty before calling trackPlay")

        videoManager.trackPlay(
            url: testUrl,
            urlref: testUrl,
            vId: testVideoId,
            duration: TimeInterval(10),
            metadata: nil,
            extra_data: nil,
            idsite: Parsely.testAPIKey
        )

        expect(videoManager.trackedVideos).to(haveCount(1), description: "A call to trackPlay should populate videoManager.accumulators with one object")
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

        expect(videoManager.trackedVideos).to(haveCount(1), description: "A call to trackPause should not remove an accumulator from videoManager.accumulators")
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

        expect(videoManager.samplerTimer).toNot(beNil(), description: "videoReset should run successfully without the VideoManager instance being paused")
        expect(videoManager.trackedVideos).to(beEmpty(), description: "A call to Parsely.track.videoManager.reset should remove a video from videoManager.trackedVideos")
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
            duration: nil
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

        expect(actualMetadata.section).to(
            equal(testSectionFirst),
            description: "The section metadata stored for a video after a call to parsely.track.videoManager.trackPlay should match the section metadata passed to that call."
        )

        let secondTestMetadata = ParselyMetadata(
            canonical_url: testUrl,
            pub_date: Date(),
            title: "test",
            authors: nil,
            image_url: nil,
            section: testSectionSecond,
            tags: nil,
            duration: nil
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

        expect(secondActualMetadata.section).to(
            equal(testSectionSecond),
            description: "The section metadata stored for a preexisting video after a call to parsely.track.videoManager.trackPlay should match the section metadata passed to that call."
        )
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

        expect(videoManager.sampleFn(key: self.testVideoKey)).to(
            beTrue(),
            description: "After a call to VideoManager.trackPlay, VideoManager.sample should return true for the viewing key"
        )
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

        expect(videoManager.sampleFn(key: self.testVideoKey)).to(
            beFalse(),
            description: "After a call to VideoManager.trackPlay followed by a call to VideoManager.trackPause, VideoManager.sample should return false for the viewing key"
        )
    }

    func testHeartbeatFn() {
        let videoManager = VideoManager(trackerInstance: parselyTestTracker)

        let dummyAccumulator = Accumulator(
            key: testVideoKey,
            accumulatedTime: 0,
            totalTime: 0,
            firstSampleTime: Date(),
            lastSampleTime: Date(),
            lastPositiveSampleTime: Date(),
            heartbeatTimeout: 0,
            contentDuration: 0,
            isEngaged: false,
            eventArgs: videoManager.generateEventArgs(
                url: testUrl,
                urlref: "",
                extra_data: nil,
                idsite: Parsely.testAPIKey
            ) as [String: Any]
        )

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

        expect(self.parselyTestTracker.eventQueue.list).to(haveCount(2), description: "A call to VideoManager should add two events to eventQueue")
    }
}
