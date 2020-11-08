import Foundation

class LargeBlockSameTagLevelToContentFilter: BaseFilter {
    override func process() -> Bool {
        var changes = false
        var tagLevel = -1
        for tb in document.textBlocks {
            let hasLabel = tb.hasLabel(VERY_LIKELY_CONTENT)
            if tb.isContent && hasLabel {
                tagLevel = tb.tagLevel
                break
            }
        }

        if tagLevel == -1 {
            return false
        }

        for tb in document.textBlocks {
            if !tb.isContent {
                if tb.numWords >= 100 && tb.tagLevel == tagLevel {
                    tb.isContent = true
                    changes = true
                }
            }
        }

        return changes
    }
}
