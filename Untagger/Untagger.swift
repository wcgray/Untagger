import Foundation

public class UntaggerSource {
    public private(set) var url: URL?
    public private(set) var htmlSourceString: String?

    init(htmlSourceString: String) {
        self.htmlSourceString = htmlSourceString
    }

    init(url: URL) {
        self.url = url
    }
}

public class UntaggerError {
    public private(set) var message: String = ""
    init(message: String) {
        self.message = message
    }
}

public typealias UntaggerResult = (title: String?, body: String?, source: UntaggerSource, error: UntaggerError?)

public class UntaggerManager {
    public static let sharedInstance = UntaggerManager()

    private static let workingQueue = DispatchQueue(label: "com.tinsoldiersoftware.Untagger")
    private var pendingDocuments: [String: UntaggerDocument] = [String: UntaggerDocument]()

    public func getText(
        htmlString: String,
        preStripJavascript: Bool = false,
        _ completion: @escaping ((UntaggerResult) -> Void)
    ) {
        let document = UntaggerDocument()
        let parser = UntaggerHTMLParser()
        parser.delegate = document
        self.pendingDocuments[document.id] = document

        document.didProcessDocument = { [weak self] doc in
            self?.pendingDocuments[doc.id] = nil

            DispatchQueue.main.async {
                completion(
                    (
                        title: doc.title,
                        body: doc.toText(),
                        source: UntaggerSource.init(htmlSourceString: htmlString),
                        error: nil
                    )
                )
            }
        }

        UntaggerManager.workingQueue.async {
            if preStripJavascript {
                parser.parseHtmlString(UntaggerManager.stripScriptTags(htmlString))
            } else {
                parser.parseHtmlString(htmlString)
            }
        }
    }

    public func getText(
        url: URL,
        preStripJavascript: Bool = false,
        _ completion: @escaping ((UntaggerResult) -> Void)
    ) {
        let document = UntaggerDocument()
        let parser = UntaggerHTMLParser()
        parser.delegate = document
        self.pendingDocuments[document.id] = document

        document.didProcessDocument = { [weak self] doc in
            self?.pendingDocuments[doc.id] = nil

            let title = doc.title
            let body = doc.toText()

            DispatchQueue.main.async {
                completion((title: title, body: body, source: UntaggerSource.init(url: url), error: nil))
            }
        }

        UntaggerManager.workingQueue.async { [weak self] in
            if let htmlString = try? String(contentsOf: url, encoding: .utf8) {
                if preStripJavascript {
                    parser.parseHtmlString(UntaggerManager.stripScriptTags(htmlString))
                } else {
                    parser.parseHtmlString(htmlString)
                }
            } else if let htmlString = try? String(contentsOf: url) {
                if preStripJavascript {
                    parser.parseHtmlString(UntaggerManager.stripScriptTags(htmlString))
                } else {
                    parser.parseHtmlString(htmlString)
                }
            } else {
                self?.pendingDocuments[document.id] = nil
                DispatchQueue.main.async {
                    completion(
                        (
                            title: nil,
                            body: nil,
                            source: UntaggerSource.init(url: url),
                            error: UntaggerError.init(message: "Could not extract url '\(url.absoluteString)'.")
                        )
                    )
                }
            }
        }
    }

    private static func stripScriptTags(_ source: String) -> String {
        var index = 0
        var scriptCount = 0
        var openStack: [NSRange] = []
        var currentSource = source
        var currentSourceCount = currentSource.count

        while index < currentSourceCount {
            let nextOpen = (currentSource as NSString).range(
                of: "<script",
                options: [],
                range: NSRange(location: index, length: currentSourceCount - index)
            )
            var openStartIndex = index
            if let rootOpenTag = openStack.first, rootOpenTag.location != NSNotFound {
                openStartIndex = rootOpenTag.location + rootOpenTag.length
            }

            let nextClose = (currentSource as NSString).range(
                    of: "</script>",
                    options: [],
                    range: NSRange(location: openStartIndex, length: currentSourceCount - openStartIndex)
                )
            if nextOpen.location != NSNotFound, nextOpen.location < nextClose.location {
                index = nextOpen.location + nextOpen.length
                openStack.append(nextOpen)
                scriptCount += 1
            } else if nextClose.location != NSNotFound, nextClose.location < nextOpen.location {
                index = nextClose.location + nextClose.length

                if scriptCount > 0 {
                    let lastOpen = openStack.removeLast()
                    scriptCount -= 1
                    if scriptCount == 0 {
                        let sourceWithScriptStrippedLength = (nextClose.location + nextClose.length) - lastOpen.location
                        let sourceWithScriptStripped = (currentSource as NSString)
                            .replacingCharacters(
                                in: NSRange(location: lastOpen.location, length: sourceWithScriptStrippedLength),
                                with: ""
                            )
                        currentSource = sourceWithScriptStripped
                        currentSourceCount -= sourceWithScriptStrippedLength
                        index = lastOpen.location - 1
                        openStack = []
                    }
                }
            } else {
                break
            }
        }

        return currentSource
    }
}
