import Foundation

class TerminatingBlocksFinder: BaseFilter {
    func startsWithNumber(_ text: String, _ postfix: String ) -> Bool {
            let len = text.count
            var j = 0
            while j < len {
                let c = text[text.index(text.startIndex, offsetBy: j)]
                let isDigit = Int("\(c)") != nil
                if !isDigit {
                    break
                }
                j += 1
            }
            if j != 0 {
                let subString = text[text.index(text.startIndex, offsetBy: j)...]
                let endingPresent = subString.hasPrefix(postfix)
                if endingPresent {
                    return true
                }
            }
            return false
    }

    override func process() -> Bool {
        var changes = false

        for tb in self.document.textBlocks {
            let numWords = tb.numWords
            if numWords < 15 {
                let text = tb.text.trimmingCharacters(in: .whitespacesAndNewlines)
                let len = text.count

                if len >= 8 {
                    let textLC = text.lowercased()

                    let numUsersResponsedIn = startsWithNumber(textLC, " users responded in")
                    let numComments = startsWithNumber(textLC, " comments")
                    let thanksFeedbackIsNowClosed = "thanks for your comments - this feedback is now closed" == textLC

                    let startsWithComments = textLC.hasPrefix("comments")

                    if startsWithComments
                        || numUsersResponsedIn || numComments
                        || textLC.hasPrefix("© reuters") || textLC.hasPrefix("please rate this")
                        || textLC.hasPrefix("post a comment") || textLC.hasPrefix("what you think...")
                        || textLC.hasPrefix("add your comment") || textLC.hasPrefix("add comment")
                        || textLC.hasPrefix("reader views") || textLC.hasPrefix("have your say")
                        || textLC.hasPrefix("reader comments") || textLC.hasPrefix("rätta artikeln")
                        || thanksFeedbackIsNowClosed {

                        tb.addLabel(INDICATES_END_OF_TEXT)

                        changes = true
                    }
                } else if tb.linkDensity == 1.0 {
                    if "Comment" == text {
                        tb.addLabel(INDICATES_END_OF_TEXT)
                    }
                }
            }
        }

        return changes
    }
}
