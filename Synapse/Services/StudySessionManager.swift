import Foundation
import SwiftData

@MainActor
final class StudySessionManager: ObservableObject {
    @Published var currentScenarios: [Scenario] = []
    @Published var currentIndex: Int = 0
    @Published var session: StudySession?
    @Published var isSessionActive: Bool = false
    @Published var isSessionComplete: Bool = false

    private let modelContext: ModelContext
    private let maxPerSession = 20
    private let maxNewScenarios = 5

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    var currentScenario: Scenario? {
        guard currentIndex < currentScenarios.count else { return nil }
        return currentScenarios[currentIndex]
    }

    var previousScenario: Scenario? {
        guard currentIndex > 0 else { return nil }
        return currentScenarios[currentIndex - 1]
    }

    var progress: Double {
        guard !currentScenarios.isEmpty else { return 0 }
        return Double(currentIndex) / Double(currentScenarios.count)
    }

    func startSession(deckID: String? = nil) {
        let scenarios = selectScenarios(deckID: deckID)
        guard !scenarios.isEmpty else { return }

        currentScenarios = scenarios
        currentIndex = 0
        isSessionActive = true
        isSessionComplete = false

        let newSession = StudySession(
            totalScenarios: scenarios.count,
            deckID: deckID
        )
        modelContext.insert(newSession)
        session = newSession
    }

    func recordAnswer(isCorrect: Bool, confidence: Confidence) {
        guard let scenario = currentScenario else { return }

        // Ensure progress exists
        if scenario.userProgress == nil {
            let progress = UserProgress()
            progress.scenario = scenario
            scenario.userProgress = progress
            modelContext.insert(progress)
        }

        if let progress = scenario.userProgress {
            let result = ReviewResult(
                isCorrect: isCorrect,
                confidence: confidence,
                scenarioDifficulty: scenario.difficulty
            )
            SpacedRepetitionEngine.updateProgress(progress, with: result)
        }

        if isCorrect {
            session?.correctCount += 1
        }
    }

    func advanceToNext() {
        currentIndex += 1
        if currentIndex >= currentScenarios.count {
            completeSession()
        }
    }

    private func completeSession() {
        session?.completedAt = Date()
        isSessionComplete = true
        isSessionActive = false
        try? modelContext.save()
        KeychainBackupService.backupProgress(context: modelContext)
    }

    private func selectScenarios(deckID: String?) -> [Scenario] {
        var descriptor = FetchDescriptor<Scenario>()
        if let deckID {
            descriptor.predicate = #Predicate<Scenario> { scenario in
                scenario.deck?.id == deckID
            }
        }

        guard let allScenarios = try? modelContext.fetch(descriptor) else { return [] }

        // Split into due and new
        var dueScenarios: [Scenario] = []
        var newScenarios: [Scenario] = []

        for scenario in allScenarios {
            if let progress = scenario.userProgress, progress.totalAttempts > 0 {
                if progress.isDue {
                    dueScenarios.append(scenario)
                }
            } else {
                newScenarios.append(scenario)
            }
        }

        // Sort due by lowest mastery first
        dueScenarios.sort { s1, s2 in
            (s1.userProgress?.masteryScore ?? 0) < (s2.userProgress?.masteryScore ?? 0)
        }

        // Take up to maxPerSession, mixing in up to maxNewScenarios
        var selected: [Scenario] = []
        let dueCount = min(dueScenarios.count, maxPerSession - min(newScenarios.count, maxNewScenarios))
        selected.append(contentsOf: dueScenarios.prefix(dueCount))

        let newCount = min(newScenarios.count, maxPerSession - selected.count)
        let newToAdd = Array(newScenarios.shuffled().prefix(newCount))
        selected.append(contentsOf: newToAdd)

        return selected.shuffled()
    }
}
