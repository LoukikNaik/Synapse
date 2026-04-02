import Foundation
import SwiftData

@Model
final class Concept {
    @Attribute(.unique) var id: String
    var name: String
    var conceptDescription: String
    var deck: Deck?

    init(
        id: String = UUID().uuidString,
        name: String,
        conceptDescription: String
    ) {
        self.id = id
        self.name = name
        self.conceptDescription = conceptDescription
    }
}
