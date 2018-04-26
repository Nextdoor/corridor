import Foundation

class CorridorRegexUtils {

    private init() {}

    class func capturedStrings(original: String, pattern: String) -> [String] {
        let ranges = capturedRanges(original: original, pattern: pattern)
        return ranges.map ({ String(original[$0]) })
    }

    class func rangeFromFirstMatch(original: String, pattern: String) -> Range<String.Index>? {
        let regex = try! NSRegularExpression(pattern: pattern)
        let match = regex.rangeOfFirstMatch(in: original,
                                            options: [],
                                            range: NSRange(location: 0, length: original.utf16.count))
        if let swiftRange = Range(match, in: original) {
            return swiftRange
        }
        return nil
    }

    class func uncapturedIsMatch(original: String, pattern: String) -> Bool {
        let regex = try! NSRegularExpression(pattern: pattern)
        let match = regex.firstMatch(in: original,
                                     options: [],
                                     range: NSRange(location: 0, length: original.utf16.count))
        return match != nil
    }

    class func uncapturedRangeFromMatch(original: String, pattern: String) -> [Range<String.Index>] {
        let regex = try! NSRegularExpression(pattern: pattern)
        let results = regex.matches(in: original, range: NSRange(location: 0, length: original.utf16.count))
        var ranges: [Range<String.Index>] = []

        for result in results {
            let match = result.range(at: 0)
            if let swiftRange = Range(match, in: original) {
                ranges.append(swiftRange)
            }
        }

        return ranges
    }

    class func replaceMatchesWithTemplate(original: String, pattern: String, template: String) -> String {
        let mutableOriginal = NSMutableString(string: original)
        let regex = try! NSRegularExpression(pattern: pattern)
        _ = regex.replaceMatches(in: mutableOriginal,
                                     options: [],
                                     range: NSRange(location: 0, length: original.utf16.count),
                                     withTemplate: template)
        return mutableOriginal as String
    }

    // MARK: Private

    private class func capturedRanges(original: String, pattern: String) -> [Range<String.Index>] {
        let regex = try! NSRegularExpression(pattern: pattern)
        let results = regex.matches(in: original, range: NSRange(location: 0, length: original.utf16.count))
        var ranges: [Range<String.Index>] = []

        for result in results {
            guard result.numberOfRanges > 1 else {
                continue
            }

            ranges.append(contentsOf: getMatchRanges(original: original, result: result))
        }
        return ranges
    }

    private class func getMatchRanges(original: String, result: NSTextCheckingResult) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        for index in 1...result.numberOfRanges - 1 {
            let match = result.range(at: index)
            if let swiftRange = Range(match, in: original) {
                ranges.append(swiftRange)
            }
        }
        return ranges
    }
}
