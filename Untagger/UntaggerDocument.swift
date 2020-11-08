import Foundation

class LabelActions {
    var labels: [String] = []
    init (_ labels: [String]) {
        self.labels = labels
    }
}

class UntaggerDocument: NSObject, UntaggerHTMLParserDelegate {
    var id: String!

    var textBlocks: [TextBlock] = []
    var title: String = ""
    var didProcessDocument: ((UntaggerDocument) -> Void)?

    var tokenBuffer: String = ""
    var textBuffer: String = ""

    var inBody: Int = 0
    var inAnchor: Int = 0
    var inIgnorableElement: Int = 0

    var tagLevel: Int = 0
    var blockTagLevel: Int = -1

    var sbLastWasWhitespace: Bool = false

    var lastEvent: String?
    var lastStartTag: String?
    var lastEndTag: String?

    var textElementIdx: Int = 0
    var offsetBlocks: Int = 0
    var currentContainedTextElements = Set<Int>()

    var flush: Bool = false
    var inAnchorText: Bool = false

    var labelStacks: [[LabelActions]] = []

    private let twoOrMoreSpaces = try! NSRegularExpression.init(pattern: "[ ]{2,}")
    private let spaceBeforePluralPossessive = try! NSRegularExpression.init(pattern: " 's")

    override init() {
        super.init()
        self.id = UUID().uuidString
    }

    func toText(includeContent: Bool = true, includeNonContent: Bool = false) -> String {
        var sb = ""

        for block in textBlocks {

            if block.isContent {
                if !includeContent {
                    continue
                }
            } else {
                if !includeNonContent {
                    continue
                }
            }

            var textBlockText = replaceMatches(source: block.text, regex: twoOrMoreSpaces, replacement: " ")
            textBlockText = replaceMatches(source: textBlockText, regex: spaceBeforePluralPossessive, replacement: "'s")

            sb += textBlockText
            sb += "\n"
        }

        sb += "\n"

        return sb
    }

    func addWhitespaceIfNecessary() {
        if !sbLastWasWhitespace {
            tokenBuffer += " "
            textBuffer += " "
            sbLastWasWhitespace = true
        }
    }

    func addLabelAction(_ labelActions: [String]) {
        let la = LabelActions.init(labelActions)

        var labelStack: [LabelActions]? = labelStacks.last
        if var labelStack = labelStack, labelStack.count > 0 {
            labelStack.append(la)
        } else {
            labelStack = [la]

            if let labelStack = labelStack {
                _ = labelStacks.removeLast()
                labelStacks.append(labelStack)
            }
        }
    }

    func flushBlocks() {
        if inBody == 0 {
            let lowercaseStartTag = lastStartTag?.lowercased()
            let isTitle = "title" == lowercaseStartTag
            if isTitle {
                let trimmedTokenBufferString = tokenBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedTokenBufferString.count > 0 {
                    title = trimmedTokenBufferString
                }
            }

            textBuffer = ""
            tokenBuffer = ""
            return
        }

        if tokenBuffer.count == 0 {
            return
        } else if tokenBuffer.count == 1, sbLastWasWhitespace {
            textBuffer = ""
            tokenBuffer = ""
            return
        }

        var numWords = 0
        var numLinkedWords = 0
        var numWrappedLines = 0
        var currentLineLength = -1
        let maxLineLength = 80
        var numTokens = 0
        var numWordsCurrentLine = 0

        let tokens = UnicodeTokenizer.tokenize(tokenBuffer)

        for token in tokens {
            if ANCHOR_TEXT_START == token {
                inAnchorText = true
            } else if ANCHOR_TEXT_END == token {
                inAnchorText = false
            } else if UnicodeTokenizer.isWord(token) {
                numTokens += 1
                numWords += 1
                numWordsCurrentLine += 1
                if inAnchorText {
                    numLinkedWords += 1
                }

                currentLineLength += token.count + 1
                if currentLineLength > maxLineLength {
                    numWrappedLines += 1
                    currentLineLength = token.count
                    numWordsCurrentLine = 1
                }
            } else {
                numTokens += 1
            }
        }

        if numTokens == 0 {
            return
        }

        var numWordsInWrappedLines: Int = 0
        if numWrappedLines == 0 {
            numWordsInWrappedLines = numWords
            numWrappedLines = 1
        } else {
            numWordsInWrappedLines = numWords - numWordsCurrentLine
        }

        let textBufferTrim = textBuffer.trimmingCharacters(in: .whitespacesAndNewlines)

        let tb = TextBlock.init()
        tb.text = textBufferTrim
        tb.containedTextElements = currentContainedTextElements
        tb.numWords = numWords
        tb.numWordsInWrappedLines = numWordsInWrappedLines
        tb.numWrappedLines = numWrappedLines
        tb.offsetBlocksEnd = offsetBlocks
        tb.offsetBlocksStart = offsetBlocks
        tb.numWordsInAnchorText = numLinkedWords
        tb.tagLevel = blockTagLevel
        tb.initDensities()

        currentContainedTextElements = Set<Int>()
        offsetBlocks += 1

        textBuffer = ""
        tokenBuffer = ""
        addLabelsToTextBlock(tb)
        textBlocks.append(tb)
        blockTagLevel = -1
    }

    private func addLabelsToTextBlock(_ textBlock: TextBlock) {
        for labelActions in self.labelStacks {
            for labelAction in labelActions {
                for label in labelAction.labels {
                    textBlock.addLabel(label)
                }
            }
        }
    }

    // MARK: HTMLParserDelegate

    func recievedCharacters(_ characters: String!) {
        textElementIdx += 1

        if flush {
            flushBlocks()
            flush = false
        }

        if inIgnorableElement != 0 {
            return
        }

        if characters.count == 0 {
            return
        }
        var startWhitespace = false
        var endWhitespace = false

        var start = 0
        var len = characters.count
        let whitespaceNormalizedString: String = (characters ?? "").components(
            separatedBy: .whitespacesAndNewlines
        ).joined(separator: " ")

        while start < characters.count {
            let c = (whitespaceNormalizedString as NSString).substring(with: NSRange(location: start, length: 1))
            if c == " " {
                startWhitespace = true
                start += 1
                len -= 1
            } else {
                break
            }
        }

        while len > 0 {
            let index = start + len - 1
            let c = (whitespaceNormalizedString as NSString).substring(with: NSRange(location: index, length: 1))
            if c == " " {
                endWhitespace = true
                len -= 1
            } else {
                break
            }
        }

        if len == 0 {
            if startWhitespace || endWhitespace {
                if !sbLastWasWhitespace {
                    textBuffer += " "
                    tokenBuffer += " "
                }
                sbLastWasWhitespace = true
            } else {
                sbLastWasWhitespace = false
            }
            lastEvent = WHITESPACE
            return
        }

        if startWhitespace {
            if !sbLastWasWhitespace {
                textBuffer += " "
                tokenBuffer += " "
            }
        }

        if blockTagLevel == -1 {
            blockTagLevel = tagLevel
        }

        let charactersToAppend = (whitespaceNormalizedString as NSString).substring(
            with: NSRange(location: start, length: len)
        )

        textBuffer += charactersToAppend
        tokenBuffer += charactersToAppend

        if endWhitespace {
            textBuffer += " "
            tokenBuffer += " "
        }

        sbLastWasWhitespace = endWhitespace
        lastEvent = CHARACTERS

        currentContainedTextElements.insert(textElementIdx)
    }

    func startElement(_ elementName: String!) {
        labelStacks.append([])

        let ta: TagAction? = defaulTagAction(tagName: elementName, document: self)
        if let ta = ta {
            if ta.changesTagLevel() {
                tagLevel += 1
            }

            flush = ta.start(tagName: elementName) || flush
        } else {
            tagLevel += 1
            flush = true
        }

        lastEvent = START_TAG
        lastStartTag = elementName
    }

    func endElement(_ elementName: String!) {
        let ta: TagAction? = defaulTagAction(tagName: elementName, document: self)
        if let ta = ta {
            flush = ta.end(tagName: elementName) || flush
        } else {
            flush = true
        }

        if ta == nil || (ta?.changesTagLevel() ?? false) {
            tagLevel -= 1
        }

        if flush {
            flushBlocks()
        }

        lastEvent = END_TAG
        lastEndTag = elementName

        labelStacks.removeLast()
    }

    func extractArticle() {
        _ = TerminatingBlocksFinder.init(document: self).process()
        _ = DocumentTitleMatchClassifier.init(document: self, title: self.title).process()
        _ = NumWordsRulesClassifierFilter.init(document: self).process()
        _ = IgnoreBlocksAfterContentFilter.init(document: self).process()
        _ = TrailingHeadlineToUntaggerFilter.init(document: self).process()
        _ = BlockProximityFusion.maxDistance1(document: self).process()
        _ = UntaggerBlockFilter.init(document: self, labelToKeep: TITLE).process()
        _ = BlockProximityFusion.maxDistance1ContentOnlySameTagLevel(document: self).process()
        _ = KeepLargestBlockBlockFilter.expandToSameTagLevelMinWords(document: self).process()
        _ = ExpandTitleToContentFilter.init(document: self).process()
        _ = LargeBlockSameTagLevelToContentFilter.init(document: self).process()
        _ = ListAtEndFilter.init(document: self).process()
    }

    func finishedParsingDocument() {
        self.lastStartTag = nil
        flushBlocks()
        self.extractArticle()

        if let didProcessDocument = didProcessDocument {
            didProcessDocument(self)
        }
    }
}
