import Foundation

class KeepLargestBlockBlockFilter : BaseFilter {
    var expandToSameLevelText : Bool = true;
    var minWords : Int = 0;
    
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
}
