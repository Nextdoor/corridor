import Foundation

/**
 A type that stores values extracted from a matched URL.
 */
public protocol CorridorRoute: Decodable {
}

/**
 A type that stores generic values extracted from a matched URL.
 Such values may be contained in multiple types of matched URLs, irrespective of the route the URL resolves to.
 */
public protocol CorridorGlobalParams: Decodable {
}

/**
 Represents URL query params that can be present in any matched URL, regardless of the route the URL resolves to.
 */
public struct GlobalQueryOptionalParamsMapping {
    public let params: [String]

    public let decoder: (_ extracted: [String: Any]) throws -> CorridorGlobalParams

    /**
     Instantiates with keys that may be contained in a URL's query, and a decoder that serializes the corresponding
     key value pairs found in the URL.

     - parameter params: A list of keys that are present in the query portion of the URL.
     - parameter decoder: Yields a CorridorGlobalParams type that contains values from the URL's query.
     - parameter extracted: A dictionary of key-value pairs that are present in the query portion of the URL.
     */
    public init(params: [String],
                decoder: @escaping (_ extracted: [String: Any]) throws -> CorridorGlobalParams) {
        self.params = params
        self.decoder = decoder
    }
}

/**
 Represents the matched URL.
 */
public struct RouteResponse {
    public let route: CorridorRoute
    public let globalParams: CorridorGlobalParams

    public init(route: CorridorRoute, globalParams: CorridorGlobalParams) {
        self.route = route
        self.globalParams = globalParams
    }
}

/**
 A no-value struct that conforms to CorridorGlobalParams.
 It is created if CorridorRouter wasn't initialized with a custom GlobalQueryOptionalParamsMapping struct.
 */
public struct CorridorGlobalParamsNone: CorridorGlobalParams {
}

struct RouteMapping {
    let attributes: CorridorAttributesProtocol
    let decoder: ([String: Any]) throws -> CorridorRoute
}

/**
 Extracts values from a URL, and converts the values into a typesafe struct called a "route".
 */
public class CorridorRouter {

    private let compiler: CorridorCompiler
    private var routeMappings: [RouteMapping] = []
    private var globalQueryOptionalParamsDecoder: (([String: Any]) throws -> CorridorGlobalParams)?

    /**
     Instantiates with params used for custom configuration
     
     - parameter CorridorTypes: Represents primitive types that can be present in URLs.
     If not present, the primitive types will be limited to the built-in ones.
     - parameter globalQueryOptionalParamsMapping: (Optional) Specifies query params that the router
     will attempt to extract from any URL.
     */
    public init(corridorTypes: CorridorTypes = CorridorTypes(),
                globalQueryOptionalParamsMapping: GlobalQueryOptionalParamsMapping?=nil) {
        let globalQueryOptionalParamNames = globalQueryOptionalParamsMapping?.params ?? []
        self.compiler = CorridorCompiler(types: corridorTypes,
                                           globalQueryOptionalParamNames: globalQueryOptionalParamNames)

        self.globalQueryOptionalParamsDecoder = globalQueryOptionalParamsMapping?.decoder
    }

    /**
     Registers a string that defines the high level structure of a URL category,
     and a block used to create a route once a matching URL is found.

     - parameter expression: Defines high level structure of a URL category
     - parameter decoder: Creates a route once a matching URL is found
     - parameter extracted: A dictionary of extracted key-value pairs from the path and query portions of the URL
     */
    public func register(_ expression: String,
                         _ decoder: @escaping (_ extracted: [String: Any]) throws -> CorridorRoute) {
        let attributes = try! self.compiler.compile(expression: expression)
        self.routeMappings.append(RouteMapping(attributes: attributes, decoder: decoder))
    }

    /**
     Attempts to match a URL with the registered expressions. If a match is found it will return a response struct.

     - parameter url: A URL
     - returns: A RouteResponse struct if the URL is matched, nil otherwise
    */
    public func attemptMatch(url: URL) -> RouteResponse? {
        let matcher = CorridorMatcher(url: url)

        for routeMapping in self.routeMappings {
            let attributes = routeMapping.attributes
            if let params = matcher.attemptMatch(attributes: attributes) {
                let globalParamsDict = matcher.globalQueryParams(queryParams: attributes.globalQueryParams)

                let route = decodeRoute(params: params, decoder: routeMapping.decoder)
                let globalParams = decodeGlobalParams(params: globalParamsDict)
                if let route = route, let globalParams = globalParams {
                    return RouteResponse(route: route, globalParams: globalParams)
                }
            }
        }

        return nil
    }

    private func decodeRoute(params: [String: Any],
                             decoder: ([String: Any]) throws -> CorridorRoute) -> CorridorRoute? {
        do {
            let route = try decoder(params)
            return route
        } catch {
            print(error)
            return nil
        }
    }

    private func decodeGlobalParams(params: [String: Any]) -> CorridorGlobalParams? {
        guard let globalQueryOptionalParamsDecoder = globalQueryOptionalParamsDecoder else {
            return CorridorGlobalParamsNone()
        }
        do {
            let globalParams = try globalQueryOptionalParamsDecoder(params)
            return globalParams
        } catch {
            print(error)
            return nil
        }
    }
}

/**
 Serializes a struct that conforms to CorridorRoute based on a dictionary of key-value pairs
 
 - parameter params: A dictionary of key-value pairs
 - parameter type: a struct type that conforms to CorridorRoute
 - returns: A serialized struct of type T
 */
/// - Throws: Serialization error if the struct can't be serialized
public func corridorResponse<T: CorridorRoute>(_ params: [String: Any], _ type: T.Type) throws -> T {
    let data = try JSONSerialization.data(withJSONObject: params, options: [])
    return try JSONDecoder().decode(type, from: data)
}

/**
 Serializes a struct that conforms to CorridorGlobalParams based on a dictionary of key-value pairs
 
 - parameter params: A dictionary of key-value pairs
 - parameter type: a struct type that conforms to CorridorGlobalParams
 - returns: A serialized struct of type T
 */
/// - Throws: Serialization error if the struct can't be serialized
public func corridorGlobalParamsResponse<T: CorridorGlobalParams>(_ params: [String: Any],
                                                                  _ type: T.Type) throws -> T {
    let data = try JSONSerialization.data(withJSONObject: params, options: [])
    return try JSONDecoder().decode(type, from: data)
}
