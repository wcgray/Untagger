import Foundation

class NumWordsRulesClassifierFilter: BaseFilter {
    private func classify(prev: TextBlock?, curr: TextBlock?, next: TextBlock?) -> Bool {
        var isContent = false

        if curr?.linkDensity ?? 0.0 <= 0.333333 {
            if prev?.linkDensity ?? 0.0 <= 0.555556 {
                if curr?.numWords ?? 0 <= 16 {
                    if next?.numWords ?? 0 <= 15 {
                        if prev?.numWords ?? 0 <= 4 {
                            isContent = false
                        } else {
                            isContent = true
                        }
                    } else {
                        isContent = true
                    }
                } else {
                    isContent = true
                }
            } else {
                if curr?.numWords ?? 0 <= 40 {
                    if next?.numWords ?? 0 <= 17 {
                        isContent = false
                    } else {
                        isContent = true
                    }
                } else {
                    isContent = true
                }
            }
        } else {
            isContent = false
        }

        return curr?.setIsContent(isContent) ?? false != isContent
    }

    override func process() -> Bool {
        var hasChanges = false

        if document.textBlocks.count == 0 {
            return false
        }

        let emptyTextBlock = TextBlock()
        emptyTextBlock.offsetBlocksEnd = -1
        emptyTextBlock.offsetBlocksStart = -1

        for (index, currentBlock) in document.textBlocks.enumerated() {
            if index > 0 {
                let prevBlock: TextBlock = index - 1 >= 0 ? document.textBlocks[index - 1] : emptyTextBlock
                let nextBlock: TextBlock = index + 1 < document.textBlocks.count ?
                    document.textBlocks[index + 1] : emptyTextBlock

                hasChanges = classify(prev: prevBlock, curr: currentBlock, next: nextBlock) || hasChanges
            }
        }

        return hasChanges
    }
}
