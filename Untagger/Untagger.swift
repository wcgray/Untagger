import Foundation

public class UntaggerSource {
    public private(set) var url : URL?
    public private(set) var htmlSourceString : String?
    
    init(htmlSourceString: String) {
        self.htmlSourceString = htmlSourceString
    }
    
    init(url: URL) {
        self.url = url
    }
}

public class UntaggerError {
    public private(set) var message : String = ""
    init(message: String) {
        self.message = message
    }
}

public typealias UntaggerResult = (title: String?, body: String?, source: UntaggerSource, error: UntaggerError?)

public class UntaggerManager {
    public static let sharedInstance = UntaggerManager()
    
    private static let workingQueue = DispatchQueue(label: "com.tinsoldiersoftware.Untagger")
    private var pendingDocuments : [String: UntaggerDocument] = [String: UntaggerDocument]()
    
    public func getText(htmlString: String, _ completion: @escaping ((UntaggerResult) -> Void)) {
        let document = UntaggerDocument()
        let parser = UntaggerHTMLParser()
        parser.delegate = document
        self.pendingDocuments[document.id] = document
        
        document.didProcessDocument = { [weak self] doc in
            self?.pendingDocuments[doc.id] = nil
            
            DispatchQueue.main.async {
                completion((title: doc.title, body: doc.toText(), source: UntaggerSource.init(htmlSourceString: htmlString), error: nil))
            }
        }
        
        UntaggerManager.workingQueue.async {
            parser.parseHtmlString(htmlString)
        }
    }
    
    public func getText(url: URL, _ completion: @escaping ((UntaggerResult) -> Void)) {
        let document = UntaggerDocument()
        let parser = UntaggerHTMLParser()
        parser.delegate = document
        self.pendingDocuments[document.id] = document
        
        document.didProcessDocument = { [weak self] doc in
            self?.pendingDocuments[doc.id] = nil
            
            DispatchQueue.main.async {
                completion((title: doc.title, body: doc.toText(), source: UntaggerSource.init(url: url), error: nil))
            }
        }
        
        UntaggerManager.workingQueue.async {
            if let htmlString = try? String(contentsOf: url, encoding: .utf8) {
                parser.parseHtmlString(htmlString)
            } else if let htmlString = try? String(contentsOf: url) {
                parser.parseHtmlString(htmlString)
            } else {
                DispatchQueue.main.async {
                    completion((title: nil, body: nil, source: UntaggerSource.init(url: url), error: UntaggerError.init(message: "Could not extract url '\(url.absoluteString)'.")))
                }
            }
        }
    }
}
