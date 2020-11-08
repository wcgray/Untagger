import Foundation

class IgnoreBlocksAfterContentFilter: BaseFilter {
    static let MIN_NUM_WORDS: Int = 60

    func getNumFullTextWordsMinTextDensity(textBlock: TextBlock, minTextDensity: Float = 9.0) -> Int {
        if textBlock.textDensity >= minTextDensity {
            return textBlock.numWords
        } else {
            return 0
        }
    }

    override func process() -> Bool {
        var changes = false

        var numWords = 0
        var foundEndOfText = false
        var index = 0

        while document.textBlocks.count > index {
            let block = document.textBlocks[index]
            index += 1

            let endOfText = block.hasLabel(INDICATES_END_OF_TEXT)
            if block.isContent {
                numWords += getNumFullTextWordsMinTextDensity(textBlock: block)
            }
            if endOfText && numWords >= IgnoreBlocksAfterContentFilter.MIN_NUM_WORDS {
                foundEndOfText = true
            }
            if foundEndOfText {
                changes = true
                block.isContent = false
            }
        }

        return changes
    }
}
