
import XCTest
@testable import Corridor

class CorridorMatcherTest: XCTestCase {

    var compiler: CorridorCompiler!

    override func setUp() {
        super.setUp()

        self.compiler = CorridorCompiler(types: CorridorTypes(),
                                           globalQueryOptionalParamNames: ["source_id"])
    }

    func testInit() {
        let url = URL(string: "http://www.example.com/newsfeed/?postId=111&source=deeplink&name=Bob%20Jones")!
        let matcher = CorridorMatcher(url: url)
        XCTAssertEqual(matcher.queryItems.count, 3)
        XCTAssertEqual(matcher.queryItems["postId"], "111")
        XCTAssertEqual(matcher.queryItems["source"], "deeplink")
        XCTAssertEqual(matcher.queryItems["name"], "Bob Jones")
        XCTAssertEqual(matcher.path, "/newsfeed")
    }

    func testMatchEmptyPathRegexNoParams() {
        let url = URL(string: "http://www.example.com/")!
        let matcher = CorridorMatcher(url: url)

        let attributes = try! compiler.compile(expression: "/.*")

        let result = matcher.attemptMatch(attributes: attributes)!

        XCTAssertNotNil(result)
        XCTAssertEqual(result.count, 0)
    }

    func testMatchPathNoParams() {
        let url = URL(string: "http://www.example.com/newsfeed/")!
        let matcher = CorridorMatcher(url: url)

        let attributes = try! compiler.compile(expression: "/newsfeed")

        let result = matcher.attemptMatch(attributes: attributes)!

        XCTAssertNotNil(result)
        XCTAssertEqual(result.count, 0)
    }

    func testMatchPathRegexNoParams() {
        let url = URL(string: "http://www.example.com/newsfeed")!
        let matcher = CorridorMatcher(url: url)

        let attributes = try! compiler.compile(expression: "/newsfeed/.*")

        let result = matcher.attemptMatch(attributes: attributes)!

        XCTAssertNotNil(result)
        XCTAssertEqual(result.count, 0)
    }

    func testMatchPathParams() {
        let url = URL(string: "http://www.example.com/newsfeed/111/comment/72172")!
        let matcher = CorridorMatcher(url: url)

        let attributes = try! compiler.compile(expression: "/newsfeed/:postId{int}/comment/:commentId")

        let result = matcher.attemptMatch(attributes: attributes)!

        XCTAssertNotNil(result)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result["postId"] as! Int, 111)
        XCTAssertEqual(result["commentId"] as! String, "72172")
    }

    func testMatchPathParamDash() {
        let url = URL(string: "http://www.example.com/team/oakland-warriors")!
        let matcher = CorridorMatcher(url: url)

        let attributes = try! compiler.compile(expression: "/team/:name{string}")

        let result = matcher.attemptMatch(attributes: attributes)!

        XCTAssertNotNil(result)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result["name"] as! String, "oakland-warriors")
    }

    func testMatchPathIgnoreQueryParams() {
        let url = URL(string: "http://www.example.com/newsfeed/?postId=111&source=deeplink")!
        let matcher = CorridorMatcher(url: url)

        let attributes = try! compiler.compile(expression: "/newsfeed")

        let result = matcher.attemptMatch(attributes: attributes)!

        XCTAssertNotNil(result)
        XCTAssertEqual(result.count, 0)
    }

    func testMatchQueryParamsEscapedEncoding() {
        let url = URL(string: "http://www.example.com/user/?name=Bob%20Jones&source=deep%20link")!
        let matcher = CorridorMatcher(url: url)

        let attributes = try! compiler.compile(expression: "/user/?:name&:source{string?}")

        let result = matcher.attemptMatch(attributes: attributes)!

        XCTAssertNotNil(result)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result["name"] as! String, "Bob Jones")
        XCTAssertEqual(result["source"] as! String, "deep link")
    }

    func testMatchOptionalQueryParamNotContained() {
        let url = URL(string: "http://www.example.com/newsfeed")!
        let matcher = CorridorMatcher(url: url)

        let attributes = try! compiler.compile(expression: "/newsfeed/?:postId{int?}")

        let result = matcher.attemptMatch(attributes: attributes)!

        XCTAssertNotNil(result)
        XCTAssertEqual(result.count, 0)
    }

    func testMatchOptionalQueryParamContained() {
        let url = URL(string: "http://www.example.com/newsfeed?postId=111")!
        let matcher = CorridorMatcher(url: url)

        let attributes = try! compiler.compile(expression: "/newsfeed/?:postId{int?}")

        let result = matcher.attemptMatch(attributes: attributes)!

        XCTAssertNotNil(result)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result["postId"] as! Int, 111)
    }

    func testMatchQueryNoPath() {
        let url = URL(string: "http://www.example.com/?postId=111")!
        let matcher = CorridorMatcher(url: url)

        let attributes = try! compiler.compile(expression: "/?:postId{int?}")

        let result = matcher.attemptMatch(attributes: attributes)!

        XCTAssertNotNil(result)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result["postId"] as! Int, 111)
    }

    func testMatchRequiredQueryParmsSuccess() {
        let url = URL(string: "http://www.example.com/newsfeed/?postId=111")!
        let matcher = CorridorMatcher(url: url)

        let attributes = try! compiler.compile(expression: "/newsfeed/?:postId{int}")

        let result = matcher.attemptMatch(attributes: attributes)!

        XCTAssertNotNil(result)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result["postId"] as! Int, 111)
    }

    func testMatchRequiredQueryParamFailure() {
        let url = URL(string: "http://www.example.com/newsfeed")!
        let matcher = CorridorMatcher(url: url)

        let attributes = try! compiler.compile(expression: "/newsfeed/?:postId{int}")

        let result = matcher.attemptMatch(attributes: attributes)

        XCTAssertNil(result)
    }

    func testMatchLiteralQueryParmsSuccess() {
        let url = URL(string: "http://www.example.com/newsfeed/?source=deeplink")!
        let matcher = CorridorMatcher(url: url)

        let attributes = try! compiler.compile(expression: "/newsfeed/?:source{'deeplink'}")

        let result = matcher.attemptMatch(attributes: attributes)!

        XCTAssertNotNil(result)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result["source"] as! String, "deeplink")
    }

    func testMatchLiteralQueryParmsFailure() {
        let url = URL(string: "http://www.example.com/newsfeed")!
        let matcher = CorridorMatcher(url: url)

        let attributes = try! compiler.compile(expression: "/newsfeed/?:source{'deeplink'}")

        let result = matcher.attemptMatch(attributes: attributes)

        XCTAssertNil(result)
    }
    
    func testMatchRequiredQueryArrayParamsSuccess() {
        var url = URL(string: "http://www.example.com/newsfeed/?postIds=15")!
        var matcher = CorridorMatcher(url: url)
        
        let attributes = try! compiler.compile(expression: "/newsfeed/?:postIds{[int]}")
        
        var result = matcher.attemptMatch(attributes: attributes)!
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result["postIds"] as! [Int], [15])
        
        url = URL(string: "http://www.example.com/newsfeed/?postIds=981,215,91")!
        matcher = CorridorMatcher(url: url)
        
        result = matcher.attemptMatch(attributes: attributes)!
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result["postIds"] as! [Int], [981, 215, 91])
    }
    
    func testMatchRequiredQueryArrayParamsFailure() {
        var url = URL(string: "http://www.example.com/newsfeed/?postIds=abc")!
        var matcher = CorridorMatcher(url: url)
        
        let attributes = try! compiler.compile(expression: "/newsfeed/?:postIds{[int]}")
        
        var result = matcher.attemptMatch(attributes: attributes)
        XCTAssertNil(result)
        
        url = URL(string: "http://www.example.com/newsfeed/?postIds=981,,91")!
        matcher = CorridorMatcher(url: url)
        
        result = matcher.attemptMatch(attributes: attributes)
        XCTAssertNil(result)
    }
    
    func testMatchOptionalQueryArrayParamsSuccess() {
        var url = URL(string: "http://www.example.com/newsfeed/?postIds=15")!
        var matcher = CorridorMatcher(url: url)
        
        let attributes = try! compiler.compile(expression: "/newsfeed/?:postIds{[int]?}")
        
        var result = matcher.attemptMatch(attributes: attributes)!
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result["postIds"] as! [Int], [15])
        
        url = URL(string: "http://www.example.com/newsfeed/?postIds=981,215,91")!
        matcher = CorridorMatcher(url: url)
        
        result = matcher.attemptMatch(attributes: attributes)!
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result["postIds"] as! [Int], [981, 215, 91])
        
        url = URL(string: "http://www.example.com/newsfeed/")!
        matcher = CorridorMatcher(url: url)
        
        result = matcher.attemptMatch(attributes: attributes)!
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result.count, 0)
    }
    
    func testMatchOptionalQueryArrayParamsFailure() {
        var url = URL(string: "http://www.example.com/newsfeed/?postIds=abc")!
        var matcher = CorridorMatcher(url: url)
        
        let attributes = try! compiler.compile(expression: "/newsfeed/?:postIds{[int]?}")
        
        var result = matcher.attemptMatch(attributes: attributes)
        XCTAssertNil(result)
        
        url = URL(string: "http://www.example.com/newsfeed/?postIds=981,,91")!
        matcher = CorridorMatcher(url: url)
        
        result = matcher.attemptMatch(attributes: attributes)
        XCTAssertNil(result)
    }

    func testMatchPathParamsAndQueryParams() {
        let str = "http://www.example.com/newsfeed/111/comment/72172/?source=deeplink&firstname=Bob&lastname=Jones"
        let url = URL(string: str)!
        let matcher = CorridorMatcher(url: url)

        let expression = "/newsfeed/:postId{int}/comment/:commentId/?:source{'deeplink'}&:firstname&:lastname{string?}"
        let attributes = try! compiler.compile(expression: expression)

        let result = matcher.attemptMatch(attributes: attributes)!

        XCTAssertNotNil(result)
        XCTAssertEqual(result.count, 5)
        XCTAssertEqual(result["postId"] as! Int, 111)
        XCTAssertEqual(result["commentId"] as! String, "72172")
        XCTAssertEqual(result["source"] as! String, "deeplink")
        XCTAssertEqual(result["firstname"] as! String, "Bob")
        XCTAssertEqual(result["lastname"] as! String, "Jones")
    }

    func testMatchContainsOptionalGlobalQueryParams() {
        let url = URL(string: "http://www.example.com/newsfeed/?postId=111&source_id=555")!
        let matcher = CorridorMatcher(url: url)

        let attributes = try! compiler.compile(expression: "/newsfeed/?:postId{int}")

        let result = matcher.globalQueryParams(queryParams: attributes.globalQueryParams)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result["source_id"] as! String, "555")
    }

    func testMatchNoOptionalGlobalQueryParams() {
        let url = URL(string: "http://www.example.com/newsfeed/?postId=111")!
        let matcher = CorridorMatcher(url: url)

        let attributes = try! compiler.compile(expression: "/newsfeed/?:postId{int}")

        let result = matcher.globalQueryParams(queryParams: attributes.globalQueryParams)
        XCTAssertEqual(result.count, 0)
    }
}
