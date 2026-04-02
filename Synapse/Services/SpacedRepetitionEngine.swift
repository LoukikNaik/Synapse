import Foundation

enum Confidence: Int, CaseIterable {
    case low = 0
    case medium = 1
    case high = 2

    var label: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }

    var intervalModifier: Double {
        switch self {
        case .low: return 0.7
        case .medium: return 1.0
        case .high: return 1.0
        }
    }
}

struct ReviewResult {
    let isCorrect: Bool
    let confidence: Confidence
    let scenarioDifficulty: Int // 1-5
}

struct SpacedRepetitionEngine {

    /// Maps (correct/wrong × confidence) → SM-2 quality score (0-5)
    static func qualityScore(isCorrect: Bool, confidence: Confidence) -> Int {
        if !isCorrect { return 1 }
        switch confidence {
        case .high:   return 5
        case .medium: return 4
        case .low:    return 3
        }
    }

    /// Difficulty modifier: harder scenarios get shorter intervals
    /// difficulty 1 → 1.2x, difficulty 3 → 1.0x, difficulty 5 → 0.8x
    static func difficultyModifier(difficulty: Int) -> Double {
        let clamped = max(1, min(5, difficulty))
        return 1.2 - (Double(clamped - 1) * 0.1)
    }

    /// Core SM-2 update with confidence and difficulty modifiers
    static func updateProgress(_ progress: UserProgress, with result: ReviewResult) {
        let q = qualityScore(isCorrect: result.isCorrect, confidence: result.confidence)

        // Standard SM-2 easiness factor update
        let efDelta = 0.1 - Double(5 - q) * (0.08 + Double(5 - q) * 0.02)
        let newEF = max(1.3, progress.easinessFactor + efDelta)
        progress.easinessFactor = newEF

        // Calculate base interval
        var newInterval: Double
        if !result.isCorrect {
            // Reset on incorrect
            progress.repetitions = 0
            newInterval = 0.5 // 12 hours
        } else {
            progress.repetitions += 1
            switch progress.repetitions {
            case 1:
                newInterval = 1
            case 2:
                newInterval = 3
            default:
                newInterval = progress.interval * newEF
            }
        }

        // Apply difficulty modifier
        newInterval *= difficultyModifier(difficulty: result.scenarioDifficulty)

        // Apply confidence modifier
        newInterval *= result.confidence.intervalModifier

        // Clamp interval to reasonable bounds (0.25 days to 365 days)
        newInterval = max(0.25, min(365, newInterval))

        progress.interval = newInterval
        progress.nextReviewDate = Date().addingTimeInterval(newInterval * 86400)
        progress.lastReviewDate = Date()

        // Update performance stats
        progress.totalAttempts += 1
        if result.isCorrect {
            progress.correctAttempts += 1
        }
        progress.lastConfidence = result.confidence.rawValue

        // Update mastery score
        progress.masteryScore = calculateMastery(progress)
    }

    /// Mastery score: weighted combination of success rate, EF, confidence, recency
    static func calculateMastery(_ progress: UserProgress) -> Double {
        guard progress.totalAttempts > 0 else { return 0 }

        // Success rate (40%)
        let successComponent = progress.successRate * 0.4

        // Easiness factor normalized to 0-1 (EF ranges 1.3-2.5+, normalize around 2.5)
        // EF of 2.5 = 1.0, EF of 1.3 = 0.0
        let efNormalized = min(1.0, max(0, (progress.easinessFactor - 1.3) / 1.2))
        let efComponent = efNormalized * 0.3

        // Confidence (20%) - last confidence normalized
        let confidenceNormalized = Double(progress.lastConfidence) / 2.0
        let confidenceComponent = confidenceNormalized * 0.2

        // Recency (10%) - how recently reviewed, decays over 30 days
        let recencyComponent: Double
        if let lastReview = progress.lastReviewDate {
            let daysSince = Date().timeIntervalSince(lastReview) / 86400
            recencyComponent = max(0, 1.0 - daysSince / 30.0) * 0.1
        } else {
            recencyComponent = 0
        }

        return min(1.0, successComponent + efComponent + confidenceComponent + recencyComponent)
    }
}
