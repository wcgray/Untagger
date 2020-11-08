import Foundation

class KeepLargestBlockBlockFilter: BaseFilter {
    var expandToSameLevelText: Bool = true
    var minWords: Int = 0

    static func expandToSameTagLevelMinWords(document: UntaggerDocument) -> KeepLargestBlockBlockFilter {
        let result = KeepLargestBlockBlockFilter.init(document: document)

        result.minWords = 150
        result.expandToSameLevelText = true

        return result
    }

    static func expandToSameTagLevel(document: UntaggerDocument) -> KeepLargestBlockBlockFilter {
        let result = KeepLargestBlockBlockFilter.init(document: document)

        result.minWords = 0
        result.expandToSameLevelText = true

        return result
    }

    override func process() -> Bool {
        if self.document.textBlocks.count < 2 {
          return false
        }

        var maxNumWords = -1
        var largestBlock: TextBlock?
        var level = -1

        var i = 0
        var n = -1
        for tb in self.document.textBlocks {
          if tb.isContent {
            let nw = tb.numWords

            if nw > maxNumWords {
              largestBlock = tb
              maxNumWords = nw

              n = i

              if expandToSameLevelText {
                level = tb.tagLevel
              }
            }
          }

          i += 1
        }

        for tb in self.document.textBlocks {
          if tb === largestBlock {
            tb.isContent = true
            tb.addLabel(VERY_LIKELY_CONTENT)
          } else {
            tb.isContent = false
            tb.addLabel(MIGHT_BE_CONTENT)
          }
        }

        if expandToSameLevelText && n != -1 {
          for tb in self.document.textBlocks[0..<(self.document.textBlocks.count - 1)] {
            let tl = tb.tagLevel
            if tl < level {
              break
            } else if tl == level {
              if tb.numWords >= minWords {
                tb.isContent = true
              }
            }
          }

          for tb in self.document.textBlocks[1..<self.document.textBlocks.count] {
            let tl = tb.tagLevel
            if tl < level {
              break
            } else if tl == level {
              if tb.numWords >= minWords {
                tb.isContent = true
              }
            }
          }

        }

        return true
    }
}
