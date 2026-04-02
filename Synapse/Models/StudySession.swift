import Foundation
import SwiftData

@Model
final class StudySession {
    @Attribute(.unique) var id: String
    var startedAt: Date
    var completedAt: Date?
    var totalScenarios: Int
    var correctCount: Int
    var deckID: String?

    var duration: TimeInterval? {
        guard let completed = completedAt else { return nil }
        return completed.timeIntervalSince(startedAt)
    }

    var accuracy: Double {
        guard totalScenarios > 0 else { return 0 }
        return Double(correctCount) / Double(totalScenarios)
    }

    init(
        id: String = UUID().uuidString,
        startedAt: Date = Date(),
        totalScenarios: Int = 0,
        correctCount: Int = 0,
        deckID: String? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.totalScenarios = totalScenarios
        self.correctCount = correctCount
        self.deckID = deckID
    }
}
