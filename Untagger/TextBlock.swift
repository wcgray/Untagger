import Foundation

class TextBlock {
    var isContent: Bool = false
    var text: String = ""

    var offsetBlocksStart: Int = 0
    var offsetBlocksEnd: Int = 0
    var tagLevel: Int = 0
    var numFullTextWords: Int = 0
    var numWords: Int = 0
    var numWordsInAnchorText: Int = 0
    var numWordsInWrappedLines: Int = 0
    var numWrappedLines: Int = 0
    var textDensity: Float = 0.0
    var linkDensity: Float = 0.0

    var labels: Set<String> = Set<String>()
    var containedTextElements: Set<Int> = Set<Int>()

    func addLabel(_ label: String) {
        labels.insert(label)
    }

    func hasLabel(_ label: String) -> Bool {
        return labels.contains(label)
    }

    func prettyPrint() {
        print("--------------------------------")
        print("isContent: \(isContent)")
        print("text: \(text) \(text.count)")
        print("offsetBlocksStart: \(offsetBlocksStart)")
        print("offsetBlocksEnd: \(offsetBlocksEnd)")
        print("numWords: \(numWords)")
        print("numWordsInAnchorText: \(numWordsInAnchorText)")
        print("numWordsInWrappedLines: \(numWordsInWrappedLines)")
        print("numWrappedLines: \(numWrappedLines)")
        print("textDensity: \(textDensity)")
        print("linkDensity: \(linkDensity)")
        print("tagLevel: \(tagLevel)")
        print("labels: \(labels)")
        print("--------------------------------")
    }

    func initDensities() {
        if self.numWordsInWrappedLines == 0 {
            self.numWordsInWrappedLines = self.numWords
            self.numWrappedLines = 1
        }
        self.textDensity = Float(self.numWordsInWrappedLines) / Float(self.numWrappedLines)
        self.linkDensity = self.numWords == 0 ? 0 : Float(self.numWordsInAnchorText) / Float(self.numWords)
    }

    func setIsContent(_ isContent: Bool) -> Bool {
        if isContent != self.isContent {
            self.isContent = isContent
            return true
        } else {
            return false
        }
    }

    func mergeNext(_ other: TextBlock) {
        self.text = "\(self.text)\n\(other.text)"

        self.numWords += other.numWords
        self.numWordsInAnchorText += other.numWordsInAnchorText

        self.numWordsInWrappedLines += other.numWordsInWrappedLines
        self.numWrappedLines += other.numWrappedLines

        self.offsetBlocksStart = min(self.offsetBlocksStart, other.offsetBlocksStart)
        self.offsetBlocksEnd = max(self.offsetBlocksEnd, other.offsetBlocksEnd)

        initDensities()

        self.isContent = self.isContent || other.isContent

        self.containedTextElements = self.containedTextElements.union(other.containedTextElements)
        self.numFullTextWords += other.numFullTextWords
        self.labels = self.labels.union(other.labels)
        self.tagLevel = min(self.tagLevel, other.tagLevel)
    }
}
