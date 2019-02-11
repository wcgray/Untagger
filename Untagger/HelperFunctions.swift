import Foundation

func log(_ items: Any...) {
    //print(items)
}

func splitOnPattern(source: String, pattern : String) -> [String] {
    if let regex = try? NSRegularExpression(pattern: pattern) {
        return splitOnRegex(source: source, regex: regex)
    } else {
        return []
    }
}

func replaceMatches(source: String, regex : NSRegularExpression, replacement : String) -> String {
    let workingTitle = NSMutableString.init(string: source)
    DocumentTitleMatchClassifier.titleRegex.replaceMatches(in: workingTitle, options: [], range: NSMakeRange(0, workingTitle.length), withTemplate: replacement)
    return workingTitle as String
}

func splitOnRegex(source: String, regex : NSRegularExpression) -> [String] {
    let matches = regex.matches(in: source, options: [], range: NSMakeRange(0, source.count))
    var results : [String] = []
    var runningIndex = 0
    for match in matches {
        let range = match.range
        let token = (source as NSString).substring(with: NSMakeRange(runningIndex, range.location - runningIndex))
        results.append(token as String)
        runningIndex = range.location + range.length
    }
    
    let token = (source as NSString).substring(with: NSMakeRange(runningIndex, source.count - runningIndex))
    results.append(token as String)
    
    return results
}

func replaceFirstRegexMatch(source: String, regex : NSRegularExpression, replacement : String) -> String {
    let matches = regex.matches(in: source, options: [], range: NSMakeRange(0, source.count))
    var result : String = ""
    if let match = matches.first {
        let range = match.range
        if range.location > 0 {
            result += (source as NSString).substring(to: range.location)
        }
        if let swiftRange = Range(range, in: source) {
            let token = (source)[swiftRange]
            result += String(token)
        }
        result += (source as NSString).substring(from: range.location + range.length)
    }
    
    return result
}
