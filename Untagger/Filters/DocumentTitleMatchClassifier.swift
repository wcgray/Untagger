import Foundation

class DocumentTitleMatchClassifier: BaseFilter {
    var potentialTitles: Set<String> = Set<String>()

    static let titleRegex = try! NSRegularExpression(pattern: "\u{00a0}")
    static let wordSplitRegex = try! NSRegularExpression(pattern: "[\\b ]+")

    static let preDash = try! NSRegularExpression(pattern: " - [^\\-]+$")
    static let postDash = try! NSRegularExpression(pattern: "^[^\\-]+ - ")

    static let veticalLineSeperator = try! NSRegularExpression(pattern: "[ ]+[\\|][ ]+")
    static let dashSeperator = try! NSRegularExpression(pattern: "[ ]+[\\-][ ]+")

    var cachedRegex: [String: NSRegularExpression] = [String: NSRegularExpression]()

    private func cachedRegex(pattern: String) -> NSRegularExpression? {
        if let regex = cachedRegex[pattern] {
            return regex
        } else if let regex = try? NSRegularExpression(pattern: pattern) {
            cachedRegex[pattern] = regex
            return regex
        } else {
            print("Failed to create regex for pattern: \(pattern)")
            return nil
        }
    }

    private func getLongestPart(title: String, pattern: String) -> String? {
        guard let regex = cachedRegex(pattern: pattern) else {
            return nil
        }

        let parts: [String] = splitOnRegex(source: title, regex: regex)
        if parts.count <= 1 {
            return nil
        }

        var longestNumWords = 0
        var longestPart = ""
        for p in parts {
            if p.contains(".com") {
                continue
            }
            let numWords = splitOnRegex(source: p, regex: DocumentTitleMatchClassifier.wordSplitRegex).count
            let pLen = p.count
            let lpLen = longestPart.count

            if numWords > longestNumWords || pLen > lpLen {
                longestNumWords = numWords
                longestPart = p
            }
        }

        if longestPart.count == 0 {
            return nil
        } else {
            let result = longestPart.trimmingCharacters(in: .whitespacesAndNewlines)
            return result
        }
    }

    private func addPotentialTitles(title: String, regex: NSRegularExpression, minWords: Int) {
        let parts = splitOnRegex(source: title, regex: regex)
        if parts.count == 1 {
            return
        }

        for p in parts {
            if p.contains(".com") {
                continue
            }

            let numWords = splitOnRegex(source: p, regex: DocumentTitleMatchClassifier.wordSplitRegex).count
            if numWords >= minWords {
                potentialTitles.insert(p)
            }
        }
    }

    init(document: UntaggerDocument, title: String?) {
        super.init(document: document)

        let titleLen = title?.count ?? 0

        if let title = title, (titleLen > 0) {
            let workingTitle = replaceMatches(
                source: title,
                regex: DocumentTitleMatchClassifier.titleRegex,
                replacement: " "
            )
            let adjustedTitle = workingTitle
                .replacingOccurrences(
                    of: "'",
                    with: ""
                )
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()

            potentialTitles.insert(adjustedTitle)

            if let p = getLongestPart(title: adjustedTitle, pattern: "[ ]*[\\|»|-][ ]*") {
                potentialTitles.insert(p)
            }

            if let p = getLongestPart(title: adjustedTitle, pattern: "[ ]*[\\|»|:][ ]*") {
                potentialTitles.insert(p)
            }

            if let p = getLongestPart(title: adjustedTitle, pattern: "[ ]*[\\|»|:\\(\\)][ ]*") {
                potentialTitles.insert(p)
            }

            if let p = getLongestPart(title: adjustedTitle, pattern: "[ ]*[\\|»|:\\(\\)\\-][ ]*") {
                potentialTitles.insert(p)
            }

            if let p = getLongestPart(title: adjustedTitle, pattern: "[ ]*[\\|»|,|:\\(\\)\\-][ ]*") {
                potentialTitles.insert(p)
            }

            if let p = getLongestPart(title: adjustedTitle, pattern: "[ ]*[\\|»|,|:\\(\\)\\-\u{00a0}][ ]*") {
                potentialTitles.insert(p)
            }

            addPotentialTitles(
                title: adjustedTitle,
                regex: DocumentTitleMatchClassifier.veticalLineSeperator,
                minWords: 4
            )
            addPotentialTitles(
                title: adjustedTitle,
                regex: DocumentTitleMatchClassifier.dashSeperator,
                minWords: 4
            )

            let rf1 = replaceFirstRegexMatch(
                source: adjustedTitle,
                regex: DocumentTitleMatchClassifier.preDash,
                replacement: ""
            )
            let rf2 = replaceFirstRegexMatch(
                source: adjustedTitle,
                regex: DocumentTitleMatchClassifier.postDash,
                replacement: ""
            )

            potentialTitles.insert(rf1)
            potentialTitles.insert(rf2)
        }
    }

    override func process() -> Bool {
        if potentialTitles.count == 0 {
            return false
        }
        var changes = false

        for tb in document.textBlocks {
            let workingTitle = replaceMatches(
                source: tb.text,
                regex: DocumentTitleMatchClassifier.titleRegex,
                replacement: " "
            )
            var adjustedText = workingTitle
                .replacingOccurrences(of: "'", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()

            if potentialTitles.contains(adjustedText) {
                tb.addLabel(TITLE)
                changes = true
                break
            }

            if let regex = cachedRegex(pattern: "[\\?\\!\\.\\-\\:]+") {
                adjustedText = replaceMatches(
                    source: tb.text,
                    regex: regex,
                    replacement: ""
                ).trimmingCharacters(in: .whitespacesAndNewlines)

                if potentialTitles.contains(adjustedText) {
                    tb.addLabel(TITLE)
                    changes = true
                    break
                }
            }
        }

        return changes
    }
}
