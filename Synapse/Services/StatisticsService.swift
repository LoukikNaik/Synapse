import Foundation
import SwiftData

@MainActor
struct StatisticsService {
    let modelContext: ModelContext

    func overallMastery() -> Double {
        let descriptor = FetchDescriptor<UserProgress>()
        guard let allProgress = try? modelContext.fetch(descriptor) else { return 0 }
        let reviewed = allProgress.filter { $0.totalAttempts > 0 }
        guard !reviewed.isEmpty else { return 0 }
        return reviewed.reduce(0) { $0 + $1.masteryScore } / Double(reviewed.count)
    }

    func dueCount(deckID: String? = nil) -> Int {
        let now = Date()
        var descriptor = FetchDescriptor<UserProgress>(
            predicate: #Predicate { $0.nextReviewDate <= now }
        )
        guard let due = try? modelContext.fetch(descriptor) else { return 0 }
        if let deckID {
            return due.filter { $0.scenario?.deck?.id == deckID }.count
        }
        return due.count
    }

    func newCount(deckID: String? = nil) -> Int {
        let descriptor = FetchDescriptor<UserProgress>(
            predicate: #Predicate { $0.totalAttempts == 0 }
        )
        guard let newItems = try? modelContext.fetch(descriptor) else { return 0 }
        if let deckID {
            return newItems.filter { $0.scenario?.deck?.id == deckID }.count
        }
        return newItems.count
    }

    func totalSessions() -> Int {
        let descriptor = FetchDescriptor<StudySession>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    func currentStreak() -> Int {
        let descriptor = FetchDescriptor<StudySession>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        guard let sessions = try? modelContext.fetch(descriptor), !sessions.isEmpty else { return 0 }

        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        // Check if there's a session today
        let todaySessions = sessions.filter { calendar.isDate($0.startedAt, inSameDayAs: checkDate) }
        if todaySessions.isEmpty {
            // Check yesterday - streak might still be valid if we haven't studied today yet
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            let yesterdaySessions = sessions.filter { calendar.isDate($0.startedAt, inSameDayAs: checkDate) }
            if yesterdaySessions.isEmpty {
                return 0
            }
        }

        // Count consecutive days with sessions going backward
        for dayOffset in 0...365 {
            let day = calendar.date(byAdding: .day, value: -dayOffset, to: calendar.startOfDay(for: Date()))!
            let hasSessions = sessions.contains { calendar.isDate($0.startedAt, inSameDayAs: day) }
            if hasSessions {
                streak += 1
            } else if dayOffset > 0 {
                break
            }
        }

        return streak
    }

    func studyDates(inLast days: Int = 30) -> Set<DateComponents> {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!
        let descriptor = FetchDescriptor<StudySession>(
            predicate: #Predicate { $0.startedAt >= startDate }
        )
        guard let sessions = try? modelContext.fetch(descriptor) else { return [] }
        return Set(sessions.map { calendar.dateComponents([.year, .month, .day], from: $0.startedAt) })
    }

    func weakConcepts(limit: Int = 5) -> [(concept: Concept, mastery: Double)] {
        let descriptor = FetchDescriptor<Concept>()
        guard let concepts = try? modelContext.fetch(descriptor) else { return [] }

        var results: [(concept: Concept, mastery: Double)] = []
        for concept in concepts {
            let scenarioDescriptor = FetchDescriptor<Scenario>()
            guard let scenarios = try? modelContext.fetch(scenarioDescriptor) else { continue }
            let related = scenarios.filter { $0.conceptIDs.contains(concept.id) }
            guard !related.isEmpty else { continue }

            let avgMastery = related.compactMap { $0.userProgress?.masteryScore }
            guard !avgMastery.isEmpty else { continue }
            let mastery = avgMastery.reduce(0, +) / Double(avgMastery.count)
            results.append((concept: concept, mastery: mastery))
        }

        return results.sorted { $0.mastery < $1.mastery }.prefix(limit).map { $0 }
    }

    func deckMastery(_ deck: Deck) -> Double {
        let reviewed = deck.scenarios.compactMap { $0.userProgress }
            .filter { $0.totalAttempts > 0 }
        guard !reviewed.isEmpty else { return 0 }
        return reviewed.reduce(0) { $0 + $1.masteryScore } / Double(reviewed.count)
    }
}
