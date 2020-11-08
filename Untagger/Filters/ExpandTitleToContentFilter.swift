import Foundation

class ExpandTitleToContentFilter: BaseFilter {
    override func process() -> Bool {
        var i = 0
        var title = -1
        var contentStart = -1
        for tb in document.textBlocks {
            let hasLabel = tb.hasLabel(TITLE)

            if contentStart == -1 && hasLabel {
                title = i
                contentStart = -1
            }
            if contentStart == -1 && tb.isContent {
                contentStart = i
            }

            i += 1
        }

        if contentStart <= title || title == -1 {
            return false
        }
        var changes = false

        let end = contentStart
        i = title

        while i < end + 1 {
            let tb =  document.textBlocks[i]
            let hasLabel = tb.hasLabel(MIGHT_BE_CONTENT)
            if hasLabel {
                changes = tb.setIsContent(true) || changes
            }

            i += 1
        }
        return changes
    }
}
