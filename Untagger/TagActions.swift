import Foundation

let TITLE: String = "untagger/TITLE"
let ARTICLE_METADATA: String = "untagger/ARTICLE_METADATA"
let INDICATES_END_OF_TEXT: String = "untagger/INDICATES_END_OF_TEXT"
let MIGHT_BE_CONTENT: String = "untagger/MIGHT_BE_CONTENT"
let VERY_LIKELY_CONTENT: String = "untagger/VERY_LIKELY_CONTENT"
let STRICTLY_NOT_CONTENT: String = "untagger/STRICTLY_NOT_CONTENT"
let HR: String = "untagger/HR"
let LI: String = "untagger/LI"

let HEADING: String = "untagger/HEADING"
let H1: String = "untagger/H1"
let H2: String = "untagger/H2"
let H3: String = "untagger/H3"

let ANCHOR_TEXT_START: String = "^#^"
let ANCHOR_TEXT_END: String = "^^^"

let START_TAG: String = "START_TAG"
let END_TAG: String = "END_TAG"
let CHARACTERS: String = "CHARACTERS"
let WHITESPACE: String = "WHITESPACE"

protocol TagAction {
    func start(tagName: String) -> Bool
    func end(tagName: String) -> Bool
    func changesTagLevel() -> Bool
}

class H1TagAction: BlockTagLabelAction {
    let document: UntaggerDocument!
    init(document: UntaggerDocument) {
        self.document = document
    }

    override func start(tagName: String) -> Bool {
        document.addLabelAction([H1, HEADING])
        return super.start(tagName: tagName)
    }
}

class H2TagAction: BlockTagLabelAction {
    let document: UntaggerDocument!
    init(document: UntaggerDocument) {
        self.document = document
    }

    override func start(tagName: String) -> Bool {
        document.addLabelAction([H2, HEADING])
        return super.start(tagName: tagName)
    }
}

class H3TagAction: BlockTagLabelAction {
    let document: UntaggerDocument!
    init(document: UntaggerDocument) {
        self.document = document
    }

    override func start(tagName: String) -> Bool {
        document.addLabelAction([H3, HEADING])
        return super.start(tagName: tagName)
    }
}

class LiTagAction: BlockTagLabelAction {
    let document: UntaggerDocument!
    init(document: UntaggerDocument) {
        self.document = document
    }

    override func start(tagName: String) -> Bool {
        document.addLabelAction([LI])
        return super.start(tagName: tagName)
    }
}

class BlockTagLabelAction: TagAction {
    func start(tagName: String) -> Bool {
        return true
    }

    func end(tagName: String) -> Bool {
        return true
    }

    func changesTagLevel() -> Bool {
        return true
    }
}

class BodyTagAction: TagAction {
    let document: UntaggerDocument!
    init(document: UntaggerDocument) {
        self.document = document
    }

    func start(tagName: String) -> Bool {
        document.flushBlocks()
        document.inBody += 1
        return false
    }

    func end(tagName: String) -> Bool {
        document.flushBlocks()
        document.inBody -= 1
        return false
    }

    func changesTagLevel() -> Bool {
        return true
    }
}

class AnchorTextTagAction: TagAction {
    let document: UntaggerDocument!
    init(document: UntaggerDocument) {
        self.document = document
    }

    func start(tagName: String) -> Bool {
        let oldValue = document.inAnchor
        document.inAnchor += 1
        if oldValue > 0 {
            let errorText = """
                Warning: SAX input contains nested A elements -- You have probably hit a bug
                in your HTML parser (e.g., NekoHTML bug #2909310). Please clean the HTML externally
                and feed it again. Trying to recover somehow...
            """
            debugPrint(errorText)

            return end(tagName: tagName)
        }
        if document.inIgnorableElement == 0 {
            document.addWhitespaceIfNecessary()
            document.tokenBuffer += ANCHOR_TEXT_START
            document.tokenBuffer += " "
            document.sbLastWasWhitespace = true
        }
        return false
    }

    func end(tagName: String) -> Bool {
        document.inAnchor -= 1
        if document.inAnchor == 0 {
            if document.inIgnorableElement == 0 {
                document.addWhitespaceIfNecessary()
                document.tokenBuffer += ANCHOR_TEXT_END
                document.tokenBuffer += " "
                document.sbLastWasWhitespace = true
            }
        }

        return false
    }

    func changesTagLevel() -> Bool {
        return true
    }
}

class InlineNoWhitespaceTagAction: TagAction {
    func start(tagName: String) -> Bool {
        return false
    }

    func end(tagName: String) -> Bool {
        return false
    }

    func changesTagLevel() -> Bool {
        return false
    }
}

class IgnorableElementTagAction: TagAction {
    let document: UntaggerDocument!
    init(document: UntaggerDocument) {
        self.document = document
    }

    func start(tagName: String) -> Bool {
        document.inIgnorableElement += 1
        return true
    }

    func end(tagName: String) -> Bool {
        document.inIgnorableElement -= 1
        return true
    }

    func changesTagLevel() -> Bool {
        return true
    }
}

func defaulTagAction(tagName: String, document: UntaggerDocument) -> TagAction? {
    var tagAction: TagAction?
    let isIgnorable = [
        "style", "script", "option", "object", "embed", "applet", "link", "noscript"
    ].contains(tagName.lowercased())
    let isInlineNoWhitespace = [
        "font", "acronym", "abbr", "var", "sub", "tt", "code", "sup", "span", "strong", "em", "i", "b", "u", "strike"
    ].contains(tagName.lowercased())

    let isBody = "body" == tagName.lowercased()
    let isAnchorText = "a" == tagName.lowercased()

    let isH3 = "h3" == tagName.lowercased()
    let isH2 = "h2" == tagName.lowercased()
    let isH1 = "h1" == tagName.lowercased()
    let isLI = "li" == tagName.lowercased()

    if isIgnorable {
        tagAction = IgnorableElementTagAction.init(document: document)
    } else if isInlineNoWhitespace {
        tagAction = InlineNoWhitespaceTagAction.init()
    } else if isBody {
        tagAction = BodyTagAction.init(document: document)
    } else if isAnchorText {
        tagAction = AnchorTextTagAction.init(document: document)
    } else if isLI {
        tagAction = LiTagAction.init(document: document)
    } else if isH1 {
        tagAction = H1TagAction.init(document: document)
    } else if isH2 {
        tagAction = H2TagAction.init(document: document)
    } else if isH3 {
        tagAction = H3TagAction.init(document: document)
    }

    return tagAction
}
