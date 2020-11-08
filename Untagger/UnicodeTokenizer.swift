import Foundation

class UnicodeTokenizer {
    static let PAT_WORD_BOUNDARY = try! NSRegularExpression(pattern: "\\b")
    static let OTHER_CHARACTER_WORD_BOUNDARY = try! NSRegularExpression(pattern: "([’%“”…])")
    static let SPACE_NOT_WORD_BOUNDARY = try! NSRegularExpression(pattern: "[ \u{2063}]+")
    static let SPACE_BOUNDARY = try! NSRegularExpression(pattern: "[ ]+")
    static let WORD_REGEX = try! NSRegularExpression(pattern: "[\\p{L}\\p{Nd}\\p{Nl}\\p{No}]")

    static func isWord(_ source: String) -> Bool {
        return WORD_REGEX.matches(in: source, options: [], range: NSRange(location: 0, length: source.count)).count > 0
    }

    static func tokenize(_ source: String) -> [String] {
        let unicodeWordBoundary = "\u{2063}"

        var workingString = replaceMatches(
            source: source,
            regex: DocumentTitleMatchClassifier.titleRegex,
            replacement: unicodeWordBoundary
        )
        workingString = replaceMatches(
            source: workingString,
            regex: UnicodeTokenizer.OTHER_CHARACTER_WORD_BOUNDARY,
            replacement: "\u{2063}$1\u{2063}"
        )

        workingString = replaceMatches(
            source: workingString,
            regex: UnicodeTokenizer.SPACE_NOT_WORD_BOUNDARY,
            replacement: " "
        )

        let trimmedString = workingString.trimmingCharacters(in: .whitespacesAndNewlines)
        let results: [String] = splitOnRegex(source: trimmedString, regex: SPACE_BOUNDARY).filter({ $0.count != 0 })

        return results
    }
}
