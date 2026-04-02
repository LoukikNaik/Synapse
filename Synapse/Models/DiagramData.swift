import Foundation

struct DiagramData: Codable {
    var nodes: [DiagramNode]
    var edges: [DiagramEdge]
}

struct DiagramNode: Codable, Identifiable {
    var id: String
    var label: String
    var type: String? // e.g., "primary", "secondary", "highlight"
}

struct DiagramEdge: Codable, Identifiable {
    var id: String { "\(from)->\(to)" }
    var from: String
    var to: String
    var label: String?
}
