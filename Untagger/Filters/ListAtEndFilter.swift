import Foundation

class ListAtEndFilter: BaseFilter {
    override func process() -> Bool {
        var changes = false
        var tagLevel = 999999

        for tb in document.textBlocks {
            let hasLabel = tb.hasLabel(VERY_LIKELY_CONTENT)
            if tb.isContent && hasLabel {
                tagLevel = tb.tagLevel
            } else {
                let hasMightBeContent = tb.hasLabel(MIGHT_BE_CONTENT)
                let hasLi = tb.hasLabel(LI)

                if tb.tagLevel > tagLevel && hasLi && hasMightBeContent && tb.linkDensity == 0 {
                    tb.isContent = true
                    changes = true
                } else {
                    tagLevel = 999999
                }
            }
        }

        return changes
    }
}
