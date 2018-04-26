import Foundation

class CorridorMatcher {
    let path: String
    let queryItems: [String: String]

    init(url: URL) {
        self.path = url.path

        var items: [String: String] = [:]
        let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        if let components = components, let componentQueryItems = components.queryItems {
            for item in componentQueryItems {
                if let name = item.name.removingPercentEncoding, let value = item.value?.removingPercentEncoding {
                    items[name] = value
                }
            }
        }
        self.queryItems = items
    }

    func attemptMatch(attributes: CorridorAttributesProtocol) -> [String: Any]? {
        var allParams: [String: Any] = [:]

        let unwrappedPathParams = attemptMatch(pathParams: attributes.pathParams,
                                                   capturedPathRegex: attributes.capturedPathRegex)
        guard let pathParams = unwrappedPathParams else {
            return nil
        }

        let unwrappedQueryParams = attemptMatch(queryParams: attributes.queryParams)
        guard let queryParams = unwrappedQueryParams else {
            return nil
        }

        for (key, value) in pathParams {
            allParams[key] = value
        }

        for (key, value) in queryParams {
            allParams[key] = value
        }

        return allParams
    }

    func globalQueryParams(queryParams: [ParamOptionalProtocol]) -> [String: Any] {
        var result: [String: Any] = [:]
        for param in queryParams {
            guard let value = self.queryItems[param.name] else {
                continue
            }
            guard let convertedValue = param.type.convert(from: value) else {
                return [:]
            }
            result[param.name] = convertedValue
        }
        return result
    }

    private func attemptMatch(pathParams: [ParamRequiredProtocol], capturedPathRegex: String) -> [String: Any]? {
        let matches = caputuredPathValues(capturedPathRegex: capturedPathRegex)
        guard matches.count == pathParams.count else {
            return nil
        }

        if pathParams.isEmpty {
            if upcapturedIsMatch(capturedPathRegex: capturedPathRegex) {
                return [:]
            } else {
                return nil
            }
        }

        var result: [String: Any] = [:]
        for (index, param) in pathParams.enumerated() {
            guard let value = param.type.convert(from: matches[index]) else {
                return nil
            }
            result[param.name] = value
        }

        return result
    }

    private func attemptMatch(queryParams: [ParamInfo]) -> [String: Any]? {
        var result: [String: Any] = [:]
        for param in queryParams {
            switch param {
            case let .required(item):
                guard let value = self.queryItems[item.name],
                    let convertedValue = item.type.convert(from: value) else {
                    return nil
                }
                result[item.name] = convertedValue
            case let .optional(item):
                guard let value = self.queryItems[item.name] else {
                    continue
                }
                guard let convertedValue = item.type.convert(from: value) else {
                    return nil
                }
                result[item.name] = convertedValue
            case let .literal(item):
                guard let value = self.queryItems[item.name], item.expectedValue == value else {
                    return nil
                }
                result[item.name] = value
            }
        }

        return result
    }

    private func caputuredPathValues(capturedPathRegex: String) -> [String] {
        var matches = CorridorRegexUtils.capturedStrings(original: self.path, pattern: capturedPathRegex)
        if matches.count == 0 && !self.path.hasSuffix("/") {
            matches = CorridorRegexUtils.capturedStrings(original: self.path+"/", pattern: capturedPathRegex)
        }
        return matches
    }

    private func upcapturedIsMatch(capturedPathRegex: String) -> Bool {
        var isMatch = CorridorRegexUtils.uncapturedIsMatch(original: self.path, pattern: capturedPathRegex)
        if !isMatch && !self.path.hasSuffix("/") {
            isMatch = CorridorRegexUtils.uncapturedIsMatch(original: self.path+"/", pattern: capturedPathRegex)
        }
        return isMatch
    }

}
