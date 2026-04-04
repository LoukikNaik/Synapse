import Foundation
import Security
import SwiftData

struct ProgressBackup: Codable {
    let scenarioID: String
    let easinessFactor: Double
    let interval: Double
    let repetitions: Int
    let nextReviewDate: Date
    let lastReviewDate: Date?
    let totalAttempts: Int
    let correctAttempts: Int
    let lastConfidence: Int
    let masteryScore: Double
}

enum KeychainBackupService {
    private static let service = "dev.synapse.app.backup"
    private static let userDecksKey = "user_decks"
    private static let progressKey = "progress"

    // MARK: - Deck Backup

    static func backupDeck(_ dto: DeckDTO) {
        var decks = loadDecks()
        if let id = dto.id {
            decks.removeAll { $0.id == id }
        }
        decks.append(dto)
        saveDecks(decks)
    }

    static func removeDeckBackup(deckID: String) {
        var decks = loadDecks()
        decks.removeAll { $0.id == deckID }
        saveDecks(decks)
    }

    static func restoreDecks() -> [DeckDTO] {
        loadDecks()
    }

    private static func loadDecks() -> [DeckDTO] {
        guard let data = load(key: userDecksKey) else { return [] }
        return (try? JSONDecoder().decode([DeckDTO].self, from: data)) ?? []
    }

    private static func saveDecks(_ decks: [DeckDTO]) {
        guard let data = try? JSONEncoder().encode(decks) else { return }
        save(key: userDecksKey, data: data)
    }

    // MARK: - Progress Backup

    @MainActor
    static func backupProgress(context: ModelContext) {
        let descriptor = FetchDescriptor<UserProgress>()
        guard let allProgress = try? context.fetch(descriptor) else { return }

        let backups = allProgress.compactMap { p -> ProgressBackup? in
            guard let scenarioID = p.scenario?.id, p.totalAttempts > 0 else { return nil }
            return ProgressBackup(
                scenarioID: scenarioID,
                easinessFactor: p.easinessFactor,
                interval: p.interval,
                repetitions: p.repetitions,
                nextReviewDate: p.nextReviewDate,
                lastReviewDate: p.lastReviewDate,
                totalAttempts: p.totalAttempts,
                correctAttempts: p.correctAttempts,
                lastConfidence: p.lastConfidence,
                masteryScore: p.masteryScore
            )
        }

        guard let data = try? JSONEncoder().encode(backups) else { return }
        save(key: progressKey, data: data)
    }

    static func restoreProgress() -> [ProgressBackup] {
        guard let data = load(key: progressKey) else { return [] }
        return (try? JSONDecoder().decode([ProgressBackup].self, from: data)) ?? []
    }

    // MARK: - Keychain Helpers

    private static func save(key: String, data: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)

        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    private static func load(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }
}
