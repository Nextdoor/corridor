
import XCTest
@testable import Corridor

class CorridorCompilerTest: XCTestCase {

    var compiler: CorridorCompiler!

    override func setUp() {
        super.setUp()

        self.compiler = CorridorCompiler(types: CorridorTypes(),
                                           globalQueryOptionalParamNames: ["source_id"])
    }

    func testNoBeginningSlashFailure() {
        do {
            _ = try self.compiler.compile(expression: "newsfeed/")
            XCTFail()
        } catch CorridorCompiler.CompilerError.invalidFormat(let message) {
            XCTAssertEqual(message, "Expression must start with \"/\"")
        } catch {
            XCTFail()
        }
    }

    func testInvalidTypePathFailure() {
        do {
            _ = try self.compiler.compile(expression: "/newsfeed/:postId{bigint}")
            XCTFail()
        } catch CorridorCompiler.CompilerError.invalidType(let message) {
            XCTAssertEqual(message, "Unrecognized type: \"bigint\"")
        } catch {
            XCTFail()
        }
    }

    func testInvalidTypeQueryRequiredFailure() {
        do {
            _ = try self.compiler.compile(expression: "/newsfeed/?:postId{bigint}")
            XCTFail()
        } catch CorridorCompiler.CompilerError.invalidType(let message) {
            XCTAssertEqual(message, "Unrecognized type: \"bigint\"")
        } catch {
            XCTFail()
        }
    }

    func testInvalidTypeQueryOptionalFailure() {
        do {
            _ = try self.compiler.compile(expression: "/newsfeed/?:postId{bigint?}")
            XCTFail()
        } catch CorridorCompiler.CompilerError.invalidType(let message) {
            XCTAssertEqual(message, "Unrecognized type: \"bigint\"")
        } catch {
            XCTFail()
        }
    }

    func testDuplicateNamedParameterFailureFirst() {
        do {
            _ = try self.compiler.compile(expression: "/newsfeed/:postId/?:postId")
            XCTFail()
        } catch CorridorCompiler.CompilerError.duplicateNamedParameter(let message) {
            XCTAssertEqual(message, "Param name \"postId\" can only be referenced once in expression")
        } catch {
            XCTFail()
        }
    }

    func testDuplicateNamedParameterFailureSecond() {
        do {
            _ = try self.compiler.compile(expression: "/newsfeed/?:source_id")
            XCTFail()
        } catch CorridorCompiler.CompilerError.duplicateNamedParameter(let message) {
            XCTAssertEqual(message, "Param name \"source_id\" can only be referenced once in expression")
        } catch {
            XCTFail()
        }
    }

    func testGlobalParams() {
        let result = try! self.compiler.compile(expression: "/newsfeed")
        XCTAssertEqual(result.pathParams.count, 0)
        XCTAssertEqual(result.queryParams.count, 0)
        XCTAssertEqual(result.globalQueryParams.count, 1)
        XCTAssertEqual(result.globalQueryParams[0].name, "source_id")
    }

    func testValidPath() {
        // no '/' at end
        let result = try! self.compiler.compile(expression: "/newsfeed/:postId/:commentId")
        XCTAssertEqual(result.pathParams.count, 2)
        XCTAssertEqual(result.queryParams.count, 0)
        XCTAssertEqual(result.pathParams[0].name, "postId")
        XCTAssertEqual("\(type(of: result.pathParams[0].type.convert(from: "abc")!))", "String")

        XCTAssertEqual(result.pathParams[1].name, "commentId")
        XCTAssertEqual("\(type(of: result.pathParams[1].type.convert(from: "abc")!))", "String")
        XCTAssertEqual(result.capturedPathRegex, "^/newsfeed/([A-Za-z0-9_.\\-~]+)/([A-Za-z0-9_.\\-~]+)$")

        // '/' at end
        _ = try! self.compiler.compile(expression: "/newsfeed/:postId/commentId:/")
        XCTAssertEqual(result.pathParams.count, 2)
        XCTAssertEqual(result.queryParams.count, 0)
        XCTAssertEqual(result.pathParams[0].name, "postId")
        
        XCTAssertEqual("\(type(of: result.pathParams[0].type.convert(from: "abc")!))", "String")
        XCTAssertEqual(result.pathParams[1].name, "commentId")
        XCTAssertEqual("\(type(of: result.pathParams[1].type.convert(from: "abc")!))", "String")
        XCTAssertEqual(result.capturedPathRegex, "^/newsfeed/([A-Za-z0-9_.\\-~]+)/([A-Za-z0-9_.\\-~]+)$")
    }

    func testValidPathTypes() {
        let result = try! self.compiler.compile(expression: "/newsfeed/:postId{string}/comment/:commentId{int}")
        XCTAssertEqual(result.pathParams.count, 2)
        XCTAssertEqual(result.globalQueryParams.count, 1)
        XCTAssertEqual(result.queryParams.count, 0)
        XCTAssertEqual(result.pathParams[0].name, "postId")
        XCTAssertEqual("\(type(of: result.pathParams[0].type.convert(from: "abc")!))", "String")
        XCTAssertEqual(result.pathParams[1].name, "commentId")
        XCTAssertEqual("\(type(of: result.pathParams[1].type.convert(from: "123")!))", "Int")
        XCTAssertEqual(result.capturedPathRegex, "^/newsfeed/([A-Za-z0-9_.\\-~]+)/comment/([A-Za-z0-9_.\\-~]+)$")
    }

    func testNoPathTypeInvalidFormat() {
        let result = try! self.compiler.compile(expression: "/newsfeed/:postIdstring}/comment/:commentId{/int}")
        XCTAssertEqual(result.pathParams.count, 0)
        XCTAssertEqual(result.queryParams.count, 0)
    }

    func testValidQueryEmptyPath() {
        let result = try! self.compiler.compile(expression: "/?:postId{int}&:commentId")
        XCTAssertEqual(result.pathParams.count, 0)
        XCTAssertEqual(result.queryParams.count, 2)
        XCTAssertEqual(nameForParamInfo(result.queryParams[0]), "postId")
        XCTAssertEqual(typeForParamInfo(result.queryParams[0]), "required")
        XCTAssertEqual(nameForParamInfo(result.queryParams[1]), "commentId")
        XCTAssertEqual(typeForParamInfo(result.queryParams[1]), "required")
        XCTAssertEqual(result.capturedPathRegex, "^/$")
    }

    func testValidQueryRequired() {
        let result = try! self.compiler.compile(expression: "/newsfeed/?:postId{int}&:commentId")
        XCTAssertEqual(result.pathParams.count, 0)
        XCTAssertEqual(result.queryParams.count, 2)
        XCTAssertEqual(nameForParamInfo(result.queryParams[0]), "postId")
        XCTAssertEqual(typeForParamInfo(result.queryParams[0]), "required")
        XCTAssertEqual(nameForParamInfo(result.queryParams[1]), "commentId")
        XCTAssertEqual(typeForParamInfo(result.queryParams[1]), "required")
        XCTAssertEqual(result.capturedPathRegex, "^/newsfeed$")
    }

    func testValidQueryOptional() {
        let result = try! self.compiler.compile(expression: "/newsfeed/?:postId{int?}&:commentId{string?}")
        XCTAssertEqual(result.pathParams.count, 0)
        XCTAssertEqual(result.queryParams.count, 2)
        XCTAssertEqual(nameForParamInfo(result.queryParams[0]), "postId")
        XCTAssertEqual(typeForParamInfo(result.queryParams[0]), "optional")
        XCTAssertEqual(nameForParamInfo(result.queryParams[1]), "commentId")
        XCTAssertEqual(typeForParamInfo(result.queryParams[1]), "optional")
        XCTAssertEqual(result.capturedPathRegex, "^/newsfeed$")
    }

    func testValidQueryLiteral() {
        let result = try! self.compiler.compile(expression: "/newsfeed/?:postId{'abcd'}&:commentId{'172362'}")
        XCTAssertEqual(result.pathParams.count, 0)
        XCTAssertEqual(result.queryParams.count, 2)
        XCTAssertEqual(nameForParamInfo(result.queryParams[0]), "postId")
        XCTAssertEqual(typeForParamInfo(result.queryParams[0]), "literal")
        XCTAssertEqual(nameForParamInfo(result.queryParams[1]), "commentId")
        XCTAssertEqual(typeForParamInfo(result.queryParams[1]), "literal")
        XCTAssertEqual(result.capturedPathRegex, "^/newsfeed$")
    }

    func testNoQueryInvalidFormat() {
        let result = try! self.compiler.compile(expression: "/newsfeed/?:postId[int}&:::commentId{string}")
        XCTAssertEqual(result.pathParams.count, 0)
        XCTAssertEqual(result.queryParams.count, 0)
    }

    func testValidPathAndQuery() {
        let result = try! self.compiler.compile(expression: "/newsfeed/:post{int}/?:action{'like_post'}&:ref{string?}")
        XCTAssertEqual(result.pathParams.count, 1)
        XCTAssertEqual(result.queryParams.count, 2)
        XCTAssertEqual(result.pathParams[0].name, "post")
        XCTAssertEqual("\(type(of: result.pathParams[0].type.convert(from: "123")!))", "Int")
        XCTAssertEqual(nameForParamInfo(result.queryParams[0]), "ref")
        XCTAssertEqual(typeForParamInfo(result.queryParams[0]), "optional")
        XCTAssertEqual(nameForParamInfo(result.queryParams[1]), "action")
        XCTAssertEqual(typeForParamInfo(result.queryParams[1]), "literal")
        XCTAssertEqual(result.capturedPathRegex, "^/newsfeed/([A-Za-z0-9_.\\-~]+)$")
    }
    
    func testValidRequiredArrayQuery() {
        let result = try! self.compiler.compile(expression: "/newsfeed/?:postIds{[int]}")
        XCTAssertEqual(result.pathParams.count, 0)
        XCTAssertEqual(result.queryParams.count, 1)
        XCTAssertEqual(nameForParamInfo(result.queryParams[0]), "postIds")
        XCTAssertEqual(typeForParamInfo(result.queryParams[0]), "required")
    }
    
    func testInvalidRequiredArrayQuery() {
        let result = try! self.compiler.compile(expression: "/newsfeed/?:postIds{int]}")
        XCTAssertEqual(result.pathParams.count, 0)
        XCTAssertEqual(result.queryParams.count, 0)
    }
    
    func testValidOptionalArrayQuery() {
        let result = try! self.compiler.compile(expression: "/newsfeed/?:postIds{[int]?}")
        XCTAssertEqual(result.pathParams.count, 0)
        XCTAssertEqual(result.queryParams.count, 1)
        XCTAssertEqual(nameForParamInfo(result.queryParams[0]), "postIds")
        XCTAssertEqual(typeForParamInfo(result.queryParams[0]), "optional")
    }
    
    func testInvalidOptionalArrayQuery() {
        let result = try! self.compiler.compile(expression: "/newsfeed/?:postIds{[int?}")
        XCTAssertEqual(result.pathParams.count, 0)
        XCTAssertEqual(result.queryParams.count, 0)
    }
    
    private func nameForParamInfo(_ paramInfo: ParamInfo) -> String {
        switch paramInfo {
        case .required(let info):
            return info.name
        case .optional(let info):
            return info.name
        case .literal(let info):
            return info.name
        }
    }

    private func typeForParamInfo(_ paramInfo: ParamInfo) -> String {
        switch paramInfo {
        case .required:
            return "required"
        case .optional:
            return "optional"
        case .literal:
            return "literal"
        }
    }
}
