import Foundation

class UntaggerBlockFilter: BaseFilter {
    var labelToKeep: String?

    init(document: UntaggerDocument, labelToKeep: String?) {
        super.init(document: document)
        self.labelToKeep = labelToKeep
    }

    override func process() -> Bool {
        var hasChanges = false

        var index = 0
        while index < document.textBlocks.count {
            let tb = document.textBlocks[index]
            if !tb.isContent && (labelToKeep == nil || !tb.hasLabel(TITLE)) {
                document.textBlocks.remove(at: index)
                index -= 1
                hasChanges = true
            }

            index += 1
        }

        return hasChanges
    }
}
