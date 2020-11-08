import Foundation

class BaseFilter {
    let document: UntaggerDocument!
    init(document: UntaggerDocument) {
        self.document = document
    }

    func process() -> Bool {
        return false
    }
}
