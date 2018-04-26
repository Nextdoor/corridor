import Foundation

protocol ParamRequiredProtocol {
    var name: String { get }
    var type: CorridorTypeConverterProtocol { get }
}

protocol ParamOptionalProtocol {
    var name: String { get }
    var type: CorridorTypeConverterProtocol { get }
}

protocol ParamLiteralProtocol {
    var name: String { get }
    var expectedValue: String { get }
}

enum ParamInfo {
    case required(ParamRequiredProtocol)
    case optional(ParamOptionalProtocol)
    case literal(ParamLiteralProtocol)
}

protocol CorridorAttributesProtocol {
    var capturedPathRegex: String { get }
    var pathParams: [ParamRequiredProtocol] { get }
    var globalQueryParams: [ParamOptionalProtocol] { get }
    var queryParams: [ParamInfo] { get }
}

// swiftlint:disable type_body_length
class CorridorCompiler {

    enum CompilerError: Error {
        case invalidType(message: String)
        case invalidFormat(message: String)
        case duplicateNamedParameter(message: String)
    }

    private let inferredName: String
    private let typeDict: [String: CorridorTypeProtocol]
    private var globalQueryParams: [ParamOptionalProtocol]!

    init(types: CorridorTypes, globalQueryOptionalParamNames: [String]) {
        self.inferredName = types.inferred.name

        var typeDict: [String: CorridorTypeProtocol] = [:]
        for corridorType in types.all {
            typeDict[corridorType.name] = corridorType
        }
        self.typeDict = typeDict
        self.globalQueryParams = try! globalQueryItems(names: globalQueryOptionalParamNames)
    }

    func compile(expression: String) throws -> CorridorAttributesProtocol {
        let (path, query) = try extractComponents(expression)
        let pathParams = try pathItems(urlPath: path)
        let queryParams = try queryItems(urlQuery: query)
        let capturedPathRegex = capturedPath(path)

        return try CorridorAttributes(capturedPathRegex: capturedPathRegex,
                                        pathParams: pathParams,
                                        globalQueryParams: globalQueryParams,
                                        queryParams: queryParams)
    }

    // MARK: Helpers

    private func extractComponents(_ expression: String) throws -> (path: String, query: String?) {
        // check for invalid characters that could break for validation (e.g. '('), and raise error

        let requiredRegex = ParamType.required.matchingQueryRegex
        let literalRegex = ParamType.literal.matchingQueryRegex
        let optionalRegex = ParamType.optional.matchingQueryRegex
        let totalQueryRegex = "(\(requiredRegex)|\(literalRegex)|\(optionalRegex))"

        let queryMatchingRegex = "\\?(\(totalQueryRegex)(\\&(\(totalQueryRegex)))*)$"
        let rangeOfQuery = CorridorRegexUtils.rangeFromFirstMatch(original: expression,
                                                                    pattern: queryMatchingRegex)

        let urlQuery: String?
        var urlPath: String

        if let rangeOfQuery = rangeOfQuery {
            urlQuery = String(expression[rangeOfQuery])
            urlPath = String(expression[expression.startIndex..<rangeOfQuery.lowerBound])
        } else {
            urlQuery = nil
            urlPath = expression
        }

        // validate path
        if !urlPath.starts(with: "/") {
            throw CompilerError.invalidFormat(message: "Expression must start with \"/\"")
        }

        return (urlPath, urlQuery)
    }

    private func queryItems(urlQuery: String?) throws -> [ParamInfo] {
        guard let urlQuery = urlQuery else {
            return []
        }

        var queryItems: [ParamInfo] = []
        for paramType in [ParamType.required, ParamType.optional, ParamType.literal] {
            let ranges = CorridorRegexUtils.uncapturedRangeFromMatch(original: urlQuery,
                                                                       pattern: "(\(paramType.matchingQueryRegex))")
            for result in ranges {
                let expression = String(urlQuery[result])
                let paramInfo: ParamInfo
                switch paramType {
                case .required:
                    paramInfo = .required(try ParamRequired(expression: expression,
                                                            inferredName: inferredName,
                                                            typeDict: typeDict))
                case .optional:
                    paramInfo = .optional(try ParamOptional(expression: expression,
                                                            typeDict: typeDict))
                case .literal:
                    paramInfo = .literal(ParamLiteral(expression: expression))
                }
                queryItems.append(paramInfo)
            }
        }
        return queryItems
    }

    private func pathItems(urlPath: String) throws -> [ParamRequiredProtocol] {
        var items: [ParamRequiredProtocol] = []
        let paramType = ParamType.required
        let ranges = CorridorRegexUtils.uncapturedRangeFromMatch(original: urlPath,
                                                                   pattern: "(\(paramType.matchingPathRegex))")
        for result in ranges {
            let expression = String(urlPath[result])
            let paramInfo = try ParamRequired(expression: expression,
                                              inferredName: inferredName,
                                              typeDict: typeDict)
            items.append(paramInfo)
        }
        return items
    }

    private func globalQueryItems(names: [String]) throws -> [ParamOptionalProtocol] {
        var items: [ParamOptionalProtocol] = []
        for name in names {
            let parmInfo = try ParamOptional(name: name, type: typeDict[inferredName]!)
            items.append(parmInfo)
        }
        return items
    }

    private func capturedPath(_ path: String) -> String {
        let validComponentCharacters = "A-Za-z0-9_.\\\\-~"
        let pattern = "(\(ParamType.required.matchingPathRegex))"
        let template = "([\(validComponentCharacters)]+)"
        var urlPath = CorridorRegexUtils.replaceMatchesWithTemplate(original: path,
                                                                      pattern: pattern,
                                                                      template: template)

        // sanitize path

        // if last character is '/', remove it
        if urlPath != "/" && urlPath.hasSuffix("/") {
            let endIndex = urlPath.index(before: urlPath.endIndex)
            urlPath = String(urlPath[urlPath.startIndex..<endIndex])
        }

        // insert '^' at beginning, and insert '$' at end
        urlPath = "^" + urlPath + "$"
        return urlPath
    }

    // MARK: Param-matching regexes

    enum ParamType {
        case required
        case optional
        case literal

        var matchingPathRegex: String {
            switch self {
            case .required:
                return "(?<=\\/)(\\:\\w+(\\{[a-z]+\\})|\\:\\w+)(?=(\\/|$))"
            case .optional:
                fatalError("Optional params are not supported in components")
            case .literal:
                fatalError("Literal params are not supported in components")
            }
        }

        var matchingQueryRegex: String {
            switch self {
            case .required:
                return "\\:\\w+(\\{[a-z]+\\})|(\\:\\w+(?=\\&|$))|\\:\\w+(\\{\\[[a-z]+\\]\\})"
            case .optional:
                return "\\:\\w+\\{[a-z]+\\?\\}|\\:\\w+\\{\\[[a-z]+\\]\\?\\}"
            case .literal:
                return "\\:\\w+\\{\\'\\w+\\'\\}"
            }
        }
    }

    // MARK: Param types

    struct ParamRequired: ParamRequiredProtocol {
        let name: String
        let type: CorridorTypeConverterProtocol

        init(expression: String,
             inferredName: String,
             typeDict: [String: CorridorTypeProtocol]) throws {
            let capturedRegexInferredType = "^\\:(\\w+)$"
            var isArrayType = false
            var matches: [String]

            let arrayCapturedRegex = "^\\:(\\w+)\\{\\[([a-z]+)\\]\\}$"
            matches = CorridorRegexUtils.capturedStrings(original: expression,
                                                         pattern: arrayCapturedRegex)
            isArrayType = !matches.isEmpty
            if !isArrayType {
                let capturedRegex = "^\\:(\\w+)\\{([a-z]+)\\}$"
                matches = CorridorRegexUtils.capturedStrings(original: expression,
                                                             pattern: capturedRegex)
            }

            if !matches.isEmpty {
                guard matches.count == 2 else {
                    fatalError("Expect to match two captured values")
                }

                self.name = String(matches[0])
                let typeName = String(matches[1])
                guard let corridorType = typeDict[typeName] else {
                    throw CompilerError.invalidType(message: "Unrecognized type: \"\(typeName)\"")
                }

                if isArrayType {
                    self.type = CorridorTypes.CorridorTypeArray(type: corridorType)
                } else {
                    self.type = corridorType
                }
            } else {
                matches = CorridorRegexUtils.capturedStrings(original: expression,
                                                                   pattern: capturedRegexInferredType)
                guard matches.count == 1 else {
                    fatalError("Expect to match one captured value")
                }

                self.name = String(matches[0])
                self.type = typeDict[inferredName]!
            }
        }
    }

    struct ParamOptional: ParamOptionalProtocol {
        let name: String
        let type: CorridorTypeConverterProtocol

        init(expression: String, typeDict: [String: CorridorTypeProtocol]) throws {
            var isArrayType = false
            var matches: [String]

            let arrayCapturedRegex = "^\\:(\\w+)\\{\\[([a-z]+)\\]\\?\\}$"
            matches = CorridorRegexUtils.capturedStrings(original: expression,
                                                         pattern: arrayCapturedRegex)

            isArrayType = !matches.isEmpty
            if !isArrayType {
                let capturedRegex = "^\\:(\\w+)\\{([a-z]+)\\?\\}$"
                matches = CorridorRegexUtils.capturedStrings(original: expression,
                                                             pattern: capturedRegex)
            }

            guard matches.count == 2 else {
                fatalError("Expect to match two captured values")
            }

            self.name = String(matches[0])
            let typeName = String(matches[1])
            guard let corridorType = typeDict[typeName] else {
                throw CompilerError.invalidType(message: "Unrecognized type: \"\(typeName)\"")
            }
            if isArrayType {
                self.type = CorridorTypes.CorridorTypeArray(type: corridorType)
            } else {
                self.type = corridorType
            }
        }

        init(name: String, type: CorridorTypeConverterProtocol) throws {
            guard CorridorRegexUtils.uncapturedIsMatch(original: name, pattern: "\\w+") else {
                fatalError("Param name has invalid characters")
            }
            self.name = name
            self.type = type
        }
    }

    struct ParamLiteral: ParamLiteralProtocol {
        let name: String
        let expectedValue: String

        init(expression: String) {
            let capturedRegex = "^\\:(\\w+)\\{\\'(\\w+)\\'\\}$"
            let matches = CorridorRegexUtils.capturedStrings(original: expression,
                                                                   pattern: capturedRegex)
            guard matches.count == 2 else {
                fatalError("Expect to match two captured values")
            }

            self.name = String(matches[0])
            self.expectedValue = String(matches[1])
        }
    }

    // MARK: Corridor attributes

    struct CorridorAttributes: CorridorAttributesProtocol {
        let capturedPathRegex: String
        let pathParams: [ParamRequiredProtocol]
        let globalQueryParams: [ParamOptionalProtocol]
        let queryParams: [ParamInfo]

        init(capturedPathRegex: String,
             pathParams: [ParamRequiredProtocol],
             globalQueryParams: [ParamOptionalProtocol],
             queryParams: [ParamInfo]) throws {
            self.capturedPathRegex = capturedPathRegex
            self.pathParams = pathParams
            self.globalQueryParams = globalQueryParams
            self.queryParams = queryParams
            try validate()
        }

        private func validate() throws {
            var paramNames: [String] = []

            paramNames += pathParams.map { $0.name }
            paramNames += globalQueryParams.map { $0.name }

            for param in queryParams {
                let name: String
                switch param {
                case let .required(item):
                    name = item.name
                case let .optional(item):
                    name = item.name
                case let .literal(item):
                    name = item.name
                }
                paramNames.append(name)
            }

            let duplicateNames = Array(Set(paramNames.filter({ (name: String) in
                paramNames.filter({ $0 == name }).count > 1
            })))
            if let duplicateName = duplicateNames.first {
                throw CompilerError.duplicateNamedParameter(message:
                    "Param name \"\(duplicateName)\" can only be referenced once in expression")
            }
        }
    }
}
// swiftlint:enable type_body_length
