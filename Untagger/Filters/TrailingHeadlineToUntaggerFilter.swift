import Foundation

class TrailingHeadlineToUntaggerFilter: BaseFilter {
    override func process() -> Bool {
        var changes = false
        let reverseTextBlocks = document.textBlocks.reversed()

        for tb in reverseTextBlocks {
            if tb.isContent {
                let hasLabel = tb.hasLabel(HEADING)
                if hasLabel {
                    tb.isContent = false
                    changes = true
                } else {
                    break
                }
            }
        }

        return changes
    }
}
