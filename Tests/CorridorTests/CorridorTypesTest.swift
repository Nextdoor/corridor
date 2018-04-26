
import XCTest
@testable import Corridor

class CorridorTypesTest: XCTestCase {

    func testInferredType() {
        let corridorTypes = CorridorTypes()
        XCTAssertEqual(corridorTypes.inferred.name, "string")
    }

    func testDefaultTypesCount() {
        let corridorTypes = CorridorTypes()
        XCTAssertEqual(corridorTypes.all.count, 3)
    }

    func testStringType() {
        let corridorTypes = CorridorTypes()
        let stringType = findCorridorType(name: "string", allTypes: corridorTypes.all)
        XCTAssertEqual(stringType.convert(from: "hello") as! String, "hello")
    }

    func testIntType() {
        let corridorTypes = CorridorTypes()
        let intType = findCorridorType(name: "int", allTypes: corridorTypes.all)
        XCTAssertEqual(intType.convert(from: "55") as! Int, 55)
    }

    func testBooltype() {
        let corridorTypes = CorridorTypes()
        let intType = findCorridorType(name: "bool", allTypes: corridorTypes.all)
        XCTAssertEqual(intType.convert(from: "True") as! Bool, true)
        XCTAssertEqual(intType.convert(from: "true") as! Bool, true)
        XCTAssertEqual(intType.convert(from: "yes") as! Bool, true)
        XCTAssertEqual(intType.convert(from: "1") as! Bool, true)
        XCTAssertEqual(intType.convert(from: "False") as! Bool, false)
        XCTAssertEqual(intType.convert(from: "false") as! Bool, false)
        XCTAssertEqual(intType.convert(from: "no") as! Bool, false)
        XCTAssertEqual(intType.convert(from: "0") as! Bool, false)
    }

    func testNonAlphabeticCustomTypeFailure() {
        let customType = MockCorridorType(name: "int32")
        do {
            _ = try CorridorTypes(customTypes: [customType])
            XCTFail()
        } catch CorridorTypes.TypeError.invalidName(let message) {
            XCTAssertEqual(message, "Corridor type \"int32\" is not alphabetic")
        } catch {
            XCTFail()
        }
    }

    func testReDeclarationCustomTypeFailure() {
        let customType = MockCorridorType(name: "string")
        do {
            _ = try CorridorTypes(customTypes: [customType])
            XCTFail()
        } catch CorridorTypes.TypeError.duplicateName(let message) {
            XCTAssertEqual(message, "Cannot re-declare corridor type \"string\"")
        } catch {
            XCTFail()
        }
    }

    func testValidCustomTypes() {
        let customType = MockCorridorType(name: "coordinate")
        let corridorTypes = try! CorridorTypes(customTypes: [customType])
        XCTAssertTrue(corridorTypes.all.contains { ( $0.name == customType.name) })
    }
    
    func testValidArrayType() {
        let corridorTypes = CorridorTypes()
        let stringType = findCorridorType(name: "string", allTypes: corridorTypes.all)
        let stringArrayType = CorridorTypes.CorridorTypeArray(type: stringType)
        let stringArray = stringArrayType.convert(from: "hello,world,123") as! [String]
        XCTAssertEqual(stringArray, ["hello", "world", "123"])
        
        let intType = findCorridorType(name: "int", allTypes: corridorTypes.all)
        let intArrayType = CorridorTypes.CorridorTypeArray(type: intType)
        let intArray = intArrayType.convert(from: "18,2222192") as! [Int]
        XCTAssertEqual(intArray, [18, 2222192])
    }
    
    func testInvalidArrayType() {
        let corridorTypes = CorridorTypes()
        let intType = findCorridorType(name: "int", allTypes: corridorTypes.all)
        let intArrayType = CorridorTypes.CorridorTypeArray(type: intType)
        XCTAssertNil(intArrayType.convert(from: "71,"))
        XCTAssertNil(intArrayType.convert(from: "71,abc"))
    }

    private func findCorridorType(name: String, allTypes: [CorridorTypeProtocol]) -> CorridorTypeProtocol {
        let index = allTypes.index(where: { ( $0.name == name) })!
        return allTypes[index]
    }

    private struct MockCorridorType: CorridorTypeProtocol {
        let name: String
        func convert(from value: String) -> Any? {
            return nil
        }
    }
}
