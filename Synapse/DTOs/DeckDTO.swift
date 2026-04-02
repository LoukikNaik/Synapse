import Foundation

struct DeckDTO: Codable {
    var id: String?
    var title: String
    var description: String
    var domain: String
    var version: String?
    var concepts: [ConceptDTO]
    var scenarios: [ScenarioDTO]
}
