import Foundation
import SwiftData

@Model
final class UserProgress {
    @Attribute(.unique) var id: String
    var scenario: Scenario?

    // SM-2 fields
    var easinessFactor: Double
    var interval: Double // in days
    var repetitions: Int
    var nextReviewDate: Date
    var lastReviewDate: Date?

    // Performance tracking
    var totalAttempts: Int
    var correctAttempts: Int
    var lastConfidence: Int // 0=low, 1=medium, 2=high
    var masteryScore: Double // 0.0 - 1.0

    var isDue: Bool {
        nextReviewDate <= Date()
    }

    var successRate: Double {
        guard totalAttempts > 0 else { return 0 }
        return Double(correctAttempts) / Double(totalAttempts)
    }

    init(
        id: String = UUID().uuidString,
        easinessFactor: Double = 2.5,
        interval: Double = 0,
        repetitions: Int = 0,
        nextReviewDate: Date = Date(),
        masteryScore: Double = 0
    ) {
        self.id = id
        self.easinessFactor = easinessFactor
        self.interval = interval
        self.repetitions = repetitions
        self.nextReviewDate = nextReviewDate
        self.lastReviewDate = nil
        self.totalAttempts = 0
        self.correctAttempts = 0
        self.lastConfidence = 1
        self.masteryScore = masteryScore
    }
}
