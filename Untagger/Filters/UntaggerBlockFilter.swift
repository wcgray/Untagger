import Foundation

class UntaggerBlockFilter : BaseFilter {
    var labelToKeep : String? = nil
    
    init(document: UntaggerDocument, labelToKeep: String?) {
        super.init(document: document)
        self.labelToKeep = labelToKeep
    }
    
    override func process() -> Bool {
        var hasChanges = false
        
        var i = 0
        while (i < document.textBlocks.count) {
            let tb = document.textBlocks[i]
            if (!tb.isContent && (labelToKeep == nil || !tb.hasLabel(TITLE))) {
                document.textBlocks.remove(at: i)
                i -= 1
                hasChanges = true
            }
            
            i += 1
        }
        
        return hasChanges
    }
}
