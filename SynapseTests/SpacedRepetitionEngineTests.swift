import XCTest
@testable import Synapse

final class SpacedRepetitionEngineTests: XCTestCase {

    // MARK: - Quality Score Tests

    func testQualityScore_correctHighConfidence_returns5() {
        XCTAssertEqual(SpacedRepetitionEngine.qualityScore(isCorrect: true, confidence: .high), 5)
    }

    func testQualityScore_correctMediumConfidence_returns4() {
        XCTAssertEqual(SpacedRepetitionEngine.qualityScore(isCorrect: true, confidence: .medium), 4)
    }

    func testQualityScore_correctLowConfidence_returns3() {
        XCTAssertEqual(SpacedRepetitionEngine.qualityScore(isCorrect: true, confidence: .low), 3)
    }

    func testQualityScore_wrongHighConfidence_returns1() {
        XCTAssertEqual(SpacedRepetitionEngine.qualityScore(isCorrect: false, confidence: .high), 1)
    }

    func testQualityScore_wrongLowConfidence_returns1() {
        XCTAssertEqual(SpacedRepetitionEngine.qualityScore(isCorrect: false, confidence: .low), 1)
    }

    // MARK: - Difficulty Modifier Tests

    func testDifficultyModifier_easy_greaterThanOne() {
        let modifier = SpacedRepetitionEngine.difficultyModifier(difficulty: 1)
        XCTAssertEqual(modifier, 1.2, accuracy: 0.01)
    }

    func testDifficultyModifier_medium_equalsOne() {
        let modifier = SpacedRepetitionEngine.difficultyModifier(difficulty: 3)
        XCTAssertEqual(modifier, 1.0, accuracy: 0.01)
    }

    func testDifficultyModifier_hard_lessThanOne() {
        let modifier = SpacedRepetitionEngine.difficultyModifier(difficulty: 5)
        XCTAssertEqual(modifier, 0.8, accuracy: 0.01)
    }

    // MARK: - Progress Update Tests

    func testUpdateProgress_correctHighConfidence_increasesInterval() {
        let progress = UserProgress(easinessFactor: 2.5, interval: 0, repetitions: 0)
        let result = ReviewResult(isCorrect: true, confidence: .high, scenarioDifficulty: 3)

        SpacedRepetitionEngine.updateProgress(progress, with: result)

        XCTAssertEqual(progress.repetitions, 1)
        XCTAssertGreaterThan(progress.interval, 0)
        XCTAssertEqual(progress.totalAttempts, 1)
        XCTAssertEqual(progress.correctAttempts, 1)
    }

    func testUpdateProgress_wrongAnswer_resetsRepetitions() {
        let progress = UserProgress(easinessFactor: 2.5, interval: 6, repetitions: 3)
        progress.totalAttempts = 3
        progress.correctAttempts = 3
        let result = ReviewResult(isCorrect: false, confidence: .medium, scenarioDifficulty: 3)

        SpacedRepetitionEngine.updateProgress(progress, with: result)

        XCTAssertEqual(progress.repetitions, 0)
        XCTAssertLessThanOrEqual(progress.interval, 1.0)
        XCTAssertEqual(progress.totalAttempts, 4)
        XCTAssertEqual(progress.correctAttempts, 3)
    }

    func testUpdateProgress_correctLowConfidence_shorterInterval() {
        let progressHigh = UserProgress(easinessFactor: 2.5, interval: 0, repetitions: 0)
        let progressLow = UserProgress(easinessFactor: 2.5, interval: 0, repetitions: 0)

        SpacedRepetitionEngine.updateProgress(progressHigh, with:
            ReviewResult(isCorrect: true, confidence: .high, scenarioDifficulty: 3))
        SpacedRepetitionEngine.updateProgress(progressLow, with:
            ReviewResult(isCorrect: true, confidence: .low, scenarioDifficulty: 3))

        XCTAssertLessThan(progressLow.interval, progressHigh.interval)
    }

    func testUpdateProgress_hardDifficulty_shorterInterval() {
        let progressEasy = UserProgress(easinessFactor: 2.5, interval: 0, repetitions: 0)
        let progressHard = UserProgress(easinessFactor: 2.5, interval: 0, repetitions: 0)

        SpacedRepetitionEngine.updateProgress(progressEasy, with:
            ReviewResult(isCorrect: true, confidence: .high, scenarioDifficulty: 1))
        SpacedRepetitionEngine.updateProgress(progressHard, with:
            ReviewResult(isCorrect: true, confidence: .high, scenarioDifficulty: 5))

        XCTAssertLessThan(progressHard.interval, progressEasy.interval)
    }

    func testUpdateProgress_easinessFactorNeverBelowMinimum() {
        let progress = UserProgress(easinessFactor: 1.3, interval: 1, repetitions: 1)
        let result = ReviewResult(isCorrect: false, confidence: .high, scenarioDifficulty: 5)

        SpacedRepetitionEngine.updateProgress(progress, with: result)

        XCTAssertGreaterThanOrEqual(progress.easinessFactor, 1.3)
    }

    // MARK: - Mastery Score Tests

    func testMastery_noAttempts_returnsZero() {
        let progress = UserProgress()
        XCTAssertEqual(SpacedRepetitionEngine.calculateMastery(progress), 0)
    }

    func testMastery_perfectPerformance_highScore() {
        let progress = UserProgress(easinessFactor: 2.5)
        progress.totalAttempts = 10
        progress.correctAttempts = 10
        progress.lastConfidence = 2
        progress.lastReviewDate = Date()

        let mastery = SpacedRepetitionEngine.calculateMastery(progress)
        XCTAssertGreaterThan(mastery, 0.8)
    }

    func testMastery_poorPerformance_lowScore() {
        let progress = UserProgress(easinessFactor: 1.3)
        progress.totalAttempts = 10
        progress.correctAttempts = 2
        progress.lastConfidence = 0
        progress.lastReviewDate = Date().addingTimeInterval(-86400 * 30)

        let mastery = SpacedRepetitionEngine.calculateMastery(progress)
        XCTAssertLessThan(mastery, 0.3)
    }
}
