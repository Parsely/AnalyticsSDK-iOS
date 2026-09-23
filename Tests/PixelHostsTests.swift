import Nimble
@testable import ParselyAnalytics
import XCTest

class PixelHostsTests: XCTestCase {

    private func makeEvent(idsite: String) -> Event {
        Event("pageview", url: "http://example.com", urlref: nil, metadata: nil, extra_data: nil, idsite: idsite)
    }

    func testHostForKnownApikey() {
        let hosts = PixelHosts(hosts: ["example.com": "p1.parsely.com"])
        XCTAssertEqual(hosts.host(for: "example.com"), "p1.parsely.com")
    }

    func testHostForUnknownApikeyIsNil() {
        let hosts = PixelHosts(hosts: ["example.com": "p1.parsely.com"])
        XCTAssertNil(hosts.host(for: "other.com"))
    }

    func testEmptyIdsiteDoesNotResolve() {
        // Review Focus 3: an event with no apikey must never resolve, even if a hand-edited
        // artifact contains an empty key.
        let hosts = PixelHosts(hosts: ["": "p1.parsely.com"])
        XCTAssertNil(hosts.host(for: ""))
    }

    func testGroupPutsEventsForOneApikeyOnOneHost() {
        let hosts = PixelHosts(hosts: ["a.com": "p1.parsely.com"])
        let result = hosts.group(events: [makeEvent(idsite: "a.com"), makeEvent(idsite: "a.com")])

        XCTAssertEqual(result.byHost.count, 1)
        XCTAssertEqual(result.byHost["p1.parsely.com"]?.count, 2)
        XCTAssertTrue(result.unresolved.isEmpty)
    }

    func testGroupCoalescesApikeysSharingAHost() {
        let hosts = PixelHosts(hosts: ["a.com": "p1.parsely.com", "b.com": "p1.parsely.com"])
        let result = hosts.group(events: [makeEvent(idsite: "a.com"), makeEvent(idsite: "b.com")])

        XCTAssertEqual(result.byHost.count, 1, "Two apikeys on one host should produce one request, not two")
        XCTAssertEqual(result.byHost["p1.parsely.com"]?.count, 2)
    }

    func testGroupSplitsApikeysOnDifferentHosts() {
        let hosts = PixelHosts(hosts: ["a.com": "p1.parsely.com", "b.com": "p1-irl.parsely.com"])
        let result = hosts.group(events: [makeEvent(idsite: "a.com"), makeEvent(idsite: "b.com")])

        XCTAssertEqual(result.byHost.count, 2)
        XCTAssertEqual(result.byHost["p1.parsely.com"]?.count, 1)
        XCTAssertEqual(result.byHost["p1-irl.parsely.com"]?.count, 1)
    }

    func testGroupSetsAsideUnresolvedEvents() {
        let hosts = PixelHosts(hosts: ["a.com": "p1.parsely.com"])
        let result = hosts.group(events: [makeEvent(idsite: "a.com"), makeEvent(idsite: "unknown.com")])

        XCTAssertEqual(result.byHost["p1.parsely.com"]?.count, 1)
        XCTAssertEqual(result.unresolved.count, 1)
        XCTAssertEqual(result.unresolved.first?.idsite, "unknown.com")
    }

    func testEmptyMapResolvesNothing() {
        let hosts = PixelHosts(hosts: [:])
        let result = hosts.group(events: [makeEvent(idsite: "a.com")])

        XCTAssertTrue(hosts.isEmpty)
        XCTAssertTrue(result.byHost.isEmpty)
        XCTAssertEqual(result.unresolved.count, 1)
    }

    func testDecodeValidArtifact() {
        let json = """
        {"version": 1, "generated_at": "2026-09-23T14:02:11Z", "hosts": {"a.com": "p1-irl.parsely.com"}}
        """
        let hosts = PixelHosts.decode(from: Data(json.utf8))

        XCTAssertEqual(hosts.host(for: "a.com"), "p1-irl.parsely.com")
    }

    func testDecodeMalformedJsonYieldsEmptyMap() {
        // Review Focus 2: no crash, no partial map, nothing sent.
        let hosts = PixelHosts.decode(from: Data("{ not json".utf8))

        XCTAssertTrue(hosts.isEmpty)
    }

    func testDecodeUnknownVersionYieldsEmptyMap() {
        let json = #"{"version": 99, "hosts": {"a.com": "p1.parsely.com"}}"#
        let hosts = PixelHosts.decode(from: Data(json.utf8))

        XCTAssertTrue(hosts.isEmpty, "A future artifact version must fail closed, not be read optimistically")
    }

    func testDecodeMissingHostsKeyYieldsEmptyMap() {
        let hosts = PixelHosts.decode(from: Data(#"{"version": 1}"#.utf8))

        XCTAssertTrue(hosts.isEmpty)
    }
}
