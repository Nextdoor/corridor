import Foundation

/**
 Encapsulates logic to extract a parameter type from a URL
 */
public protocol CorridorTypeConverterProtocol {
    /**
     Attempts to convert a string value to another primitive type.
     */
    func convert(from value: String) -> Any?
}

/**
 Represents a parameter type to extract from a URL.
 */
public protocol CorridorTypeProtocol: CorridorTypeConverterProtocol {
    /**
     Name of the type. Must be alphabetic.
    */
    var name: String { get }
}

/**
 Registers all named param types.
 */
public class CorridorTypes {
    let inferred: CorridorTypeProtocol
    let all: [CorridorTypeProtocol]

    /**
     Represents an invalid type.
     */
    public enum TypeError: Error {
        /**
         Type name violates naming rules.
         */
        case invalidName(message: String)
        /**
         Type name is equal to another type name that is already registered.
         */
        case duplicateName(message: String)
    }

    /**
     Instantiates with built-in types.
     */
    public convenience init() {
        self.init(with: [])
    }

    /**
     Instantiates with built-in types and a passed in list of custom types.
     
     - parameter customTypes: A list of types that conform to CorridorTypeProtocol.
     */
    /// - Throws: An error of type `TypeError`.
    public convenience init(customTypes: [CorridorTypeProtocol]) throws {
        self.init(with: customTypes)
        try validate()
    }

    private init(with customTypes: [CorridorTypeProtocol]) {
        let typeString = CorridorTypeString()
        let defaultTypes: [CorridorTypeProtocol] = [CorridorTypeInt(), typeString, CorridorTypeBool()]
        self.inferred = typeString
        self.all = defaultTypes + customTypes
    }

    private func validate() throws {
        let names = all.map { $0.name }
        var tmpNames: Set<String> = []
        for name in names {
            if tmpNames.contains(name) {
                throw TypeError.duplicateName(message: "Cannot re-declare corridor type \"\(name)\"")
            }
            if !isAlphabetic(value: name) {
                throw TypeError.invalidName(message: "Corridor type \"\(name)\" is not alphabetic")
            }
            tmpNames.insert(name)
        }
    }

    private func isAlphabetic(value: String) -> Bool {
        return value.range(of: "[^(a-zA-Z)+]", options: .regularExpression) == nil
    }

    private struct CorridorTypeInt: CorridorTypeProtocol {
        let name = "int"

        func convert(from value: String) -> Any? {
            return Int(value)
        }
    }

    private struct CorridorTypeString: CorridorTypeProtocol {
        let name = "string"

        func convert(from value: String) -> Any? {
            return value
        }
    }

    private struct CorridorTypeBool: CorridorTypeProtocol {
        let name = "bool"

        func convert(from value: String) -> Any? {
            switch value {
            case "True", "true", "yes", "1":
                return true
            case "False", "false", "no", "0":
                return false
            default:
                return nil
            }
        }
    }

    struct CorridorTypeArray: CorridorTypeConverterProtocol {
        let type: CorridorTypeConverterProtocol

        init(type: CorridorTypeConverterProtocol) {
            self.type = type
        }

        func convert(from value: String) -> Any? {
            let items = value.components(separatedBy: ",")
            var convertedItems: [Any] = []
            for item in items {
                guard let convertedItem = type.convert(from: item) else {
                    return nil
                }
                convertedItems.append(convertedItem)
            }
            return convertedItems
        }
    }
}
