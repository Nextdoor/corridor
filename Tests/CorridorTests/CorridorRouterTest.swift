
import XCTest
@testable import Corridor

class CorridorRouterTest: XCTestCase {

    var router: CorridorRouter!
    
    override func setUp() {
        super.setUp()
        self.router = CorridorRouter()
    }
    
    func testCorridorResponseValid() {
        let response = try! corridorResponse(["postId": 132872], MockViewPost.self)
        XCTAssertEqual(response.postId, 132872)
    }
    
    func testCorridorResponseFailure() {
        XCTAssertThrowsError(try corridorResponse(["postId": "132872"], MockViewPost.self))
    }
    
    func testRegisterRouteValid() {
        XCTAssertNoThrow(router.register("/newsfeed/:postId{int}", { try corridorResponse($0, MockViewPost.self )}))
    }
    
    func testMatchFirstRegisteredSuccess() {
        self.router.register("/newsfeed/?:postId{int?}", {
            try corridorResponse($0, MockViewPost.self )})
        
        let url = URL(string: "http://www.example.com/newsfeed?postId=111")!
        let result = self.router.attemptMatch(url: url)!
        XCTAssertTrue(result.route is MockViewPost)
    }
    
    func testMatchSecondRegisteredSuccess() {
        self.router.register("/newsfeed/:postId{int}", {
            try corridorResponse($0, MockViewPost.self )})
        
        self.router.register("/newsfeed/", {
            try corridorResponse($0, MockNewsfeed.self )})
        
        let url = URL(string: "http://www.example.com/newsfeed")!
        let result = self.router.attemptMatch(url: url)!
        XCTAssertTrue(result.route is MockNewsfeed)
    }
    
    func testMatchWildcardSuccess() {
        self.router.register("/newsfeed/.*", {
            try corridorResponse($0, MockNewsfeed.self )})
        let url = URL(string: "http://www.example.com/newsfeed")!
        let result = self.router.attemptMatch(url: url)!
        XCTAssertTrue(result.route is MockNewsfeed)
    }
    
    func testMatchWildcardSecondRegisteredSuccess() {
        self.router.register("/newsfeed/:postId{int}", {
            try corridorResponse($0, MockViewPost.self )})
        
        self.router.register("/newsfeed/.*", {
            try corridorResponse($0, MockNewsfeed.self )})
        
        let url = URL(string: "http://www.example.com/newsfeed/myNeighborhood/")!
        let result = self.router.attemptMatch(url: url)!
        XCTAssertTrue(result.route is MockNewsfeed)
    }
    
    func testNoMatch() {
        self.router.register("/newsfeed/:postId{int}", {
            try corridorResponse($0, MockViewPost.self )})
        
        self.router.register("/newsfeed/", {
            try corridorResponse($0, MockNewsfeed.self )})
        
        let url = URL(string: "http://www.example.com/newsfeed/111/thanks")!
        let result = self.router.attemptMatch(url: url)
        XCTAssertNil(result)
    }
    
    func testNoMatchResponseSerializationFailure() {
        self.router.register("/newsfeed/:postId{int}", {
            try corridorResponse($0, MockViewPost.self )})
        
        self.router.register("/newsfeed/.*", {
            try corridorResponse($0, MockNewsfeed.self )})
        
        let url = URL(string: "http://www.example.com/abcdefg")!
        let result = self.router.attemptMatch(url: url)
        XCTAssertNil(result)
    }
    
    struct MockViewPost: CorridorRoute {
        let postId: Int
    }
    
    struct MockNewsfeed: CorridorRoute {}

}
