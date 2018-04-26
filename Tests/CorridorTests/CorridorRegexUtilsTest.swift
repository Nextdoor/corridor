
import XCTest
@testable import Corridor

class CorridorRegexUtilsTest: XCTestCase {

    func testReplaceMatchesWithTemplate() {
        let result = CorridorRegexUtils.replaceMatchesWithTemplate(original: "/posts/TTT/comment/TTT",
                                                                     pattern: "TTT",
                                                                     template: "([A-Za-z0-9_.-~]+)")
        XCTAssertEqual(result, "/posts/([A-Za-z0-9_.-~]+)/comment/([A-Za-z0-9_.-~]+)")
    }

    func testRangeFromFirstMatch() {
        let url = "/posts/552/comment/111"
        let range = CorridorRegexUtils.rangeFromFirstMatch(original: url,
                                                             pattern: "([0-9]+)")
        XCTAssertEqual(NSRange(range!, in: url), NSRange(location: 7, length: 3))
    }

    func testUncapturedIsMatch() {
        let url = "/newsfeed"
        XCTAssertTrue(CorridorRegexUtils.uncapturedIsMatch(original: url, pattern: "^/newsfeed$"))
        XCTAssertFalse(CorridorRegexUtils.uncapturedIsMatch(original: url, pattern: "^/stories$"))
    }

    func testCapturedStrings() {
        let result = CorridorRegexUtils.capturedStrings(original: "/posts/552/comment/111",
                                                          pattern: "([0-9]+)")
        XCTAssertEqual(result, ["552", "111"])
    }

    func testUncapturedRangeFromMatch() {
        let url = "/posts/552/comment/111"
        let result = CorridorRegexUtils.uncapturedRangeFromMatch(original: url,
                                                                   pattern: "([0-9]+)")

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(NSRange(result[0], in: url), NSRange(location: 7, length: 3))
        XCTAssertEqual(NSRange(result[1], in: url), NSRange(location: 19, length: 3))
    }
}
