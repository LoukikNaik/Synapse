import Foundation

struct ScenarioDTO: Codable {
    var id: String
    var type: String // "decision", "diagram", "hybrid"
    var difficulty: Int
    var tags: [String]?
    var concepts: [String] // concept IDs
    var prompt: PromptDTO
    var options: [OptionDTO]
    var correctOptionId: String
    var explanation: ExplanationDTO
    var diagram: DiagramDTO?
}

struct PromptDTO: Codable {
    var context: String
    var constraints: [String]?
    var question: String
}

struct OptionDTO: Codable {
    var id: String
    var label: String
    var description: String
}

struct ExplanationDTO: Codable {
    var reasoning: String
    var tradeoffs: String
    var keyTakeaway: String
    var commonMistake: String
}

struct DiagramDTO: Codable {
    var nodes: [DiagramNodeDTO]
    var edges: [DiagramEdgeDTO]
}

struct DiagramNodeDTO: Codable {
    var id: String
    var label: String
    var type: String?
}

struct DiagramEdgeDTO: Codable {
    var from: String
    var to: String
    var label: String?
}
