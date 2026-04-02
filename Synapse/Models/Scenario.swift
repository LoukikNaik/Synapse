import Foundation
import SwiftData

enum ScenarioType: String, Codable {
    case decision
    case diagram
    case hybrid
}

@Model
final class Scenario {
    @Attribute(.unique) var id: String
    var type: ScenarioType
    var difficulty: Int // 1-5
    var tags: [String]
    var conceptIDs: [String]

    // Prompt fields (flattened, no separate model needed)
    var context: String
    var constraints: [String]
    var question: String

    // Options
    @Relationship(deleteRule: .cascade, inverse: \Option.scenario)
    var options: [Option]

    var correctOptionID: String

    // Explanation fields (flattened)
    var reasoning: String
    var tradeoffs: String
    var keyTakeaway: String
    var commonMistake: String

    // Optional diagram data (stored as JSON blob)
    var diagramDataJSON: Data?

    var deck: Deck?

    @Relationship(deleteRule: .cascade, inverse: \UserProgress.scenario)
    var userProgress: UserProgress?

    init(
        id: String = UUID().uuidString,
        type: ScenarioType = .decision,
        difficulty: Int = 3,
        tags: [String] = [],
        conceptIDs: [String] = [],
        context: String,
        constraints: [String] = [],
        question: String,
        correctOptionID: String,
        reasoning: String = "",
        tradeoffs: String = "",
        keyTakeaway: String = "",
        commonMistake: String = ""
    ) {
        self.id = id
        self.type = type
        self.difficulty = difficulty
        self.tags = tags
        self.conceptIDs = conceptIDs
        self.context = context
        self.constraints = constraints
        self.question = question
        self.options = []
        self.correctOptionID = correctOptionID
        self.reasoning = reasoning
        self.tradeoffs = tradeoffs
        self.keyTakeaway = keyTakeaway
        self.commonMistake = commonMistake
    }

    var decodedDiagramData: DiagramData? {
        guard let data = diagramDataJSON else { return nil }
        return try? JSONDecoder().decode(DiagramData.self, from: data)
    }

    var sortedOptions: [Option] {
        options.sorted { $0.label < $1.label }
    }
}
