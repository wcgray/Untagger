import Foundation

class BlockProximityFusion: BaseFilter {
    var maxBlocksDistance: Int = 1
    var contentOnly: Bool = false
    var sameTagLevelOnly: Bool = false

    static func maxDistance1ContentOnlySameTagLevel(document: UntaggerDocument) -> BlockProximityFusion {
        let filter = BlockProximityFusion.init(document: document)
        filter.maxBlocksDistance = 1
        filter.contentOnly = true
        filter.sameTagLevelOnly = true

        return filter
    }

    static func maxDistance1(document: UntaggerDocument) -> BlockProximityFusion {
        let filter = BlockProximityFusion.init(document: document)
        filter.maxBlocksDistance = 1
        filter.contentOnly = false
        filter.sameTagLevelOnly = false

        return filter
    }

    override func process() -> Bool {
        if document.textBlocks.count < 2 {
            return false
        }
        var changes = false
        var prevBlock: TextBlock?

        var offset = -1
        if self.contentOnly {
            prevBlock = nil
            offset = 0

            for tb in document.textBlocks {
                offset += 1
                if tb.isContent {
                    prevBlock = tb
                    break
                }
            }
            if prevBlock == nil {
                return false
            }
        } else {
            prevBlock = document.textBlocks.first
            offset = 1
        }

        var i = offset
        while i < document.textBlocks.count {
            let block = document.textBlocks[i]

            if !block.isContent {
                prevBlock = block
                i += 1
                continue
            }

            if let unwPrevBlock = prevBlock,
               (block.offsetBlocksStart - unwPrevBlock.offsetBlocksEnd - 1) <= self.maxBlocksDistance {
                var ok = true
                if self.contentOnly {
                    if !unwPrevBlock.isContent || !block.isContent {
                        ok = false
                    }
                }
                if ok && self.sameTagLevelOnly && unwPrevBlock.tagLevel != block.tagLevel {
                    ok = false
                }
                if ok {
                    unwPrevBlock.mergeNext(block)
                    document.textBlocks.remove(at: i)
                    i -= 1
                    changes = true
                } else {
                    prevBlock = block
                }
            } else {
                prevBlock = block
            }
            i += 1
        }

        return changes
    }
}
