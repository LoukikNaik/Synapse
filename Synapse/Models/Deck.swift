import Foundation
import SwiftData

@Model
final class Deck {
    @Attribute(.unique) var id: String
    var title: String
    var deckDescription: String
    var domain: String
    var version: String
    var createdAt: Date
    var importedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Concept.deck)
    var concepts: [Concept]

    @Relationship(deleteRule: .cascade, inverse: \Scenario.deck)
    var scenarios: [Scenario]

    init(
        id: String = UUID().uuidString,
        title: String,
        deckDescription: String,
        domain: String,
        version: String = "1.0",
        createdAt: Date = Date(),
        importedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.deckDescription = deckDescription
        self.domain = domain
        self.version = version
        self.createdAt = createdAt
        self.importedAt = importedAt
        self.concepts = []
        self.scenarios = []
    }
}
