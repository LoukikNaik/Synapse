import SwiftUI
import SwiftData

@main
struct SynapseApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([
                Deck.self,
                Concept.self,
                Scenario.self,
                Option.self,
                UserProgress.self,
                StudySession.self
            ])
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    @Environment(\.scenePhase) private var scenePhase
    @State private var isImporting = true

    var body: some Scene {
        WindowGroup {
            if isImporting {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading decks...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
                .task {
                    await importAndRestore()
                    isImporting = false
                }
            } else {
                MainTabView()
            }
        }
        .modelContainer(modelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                KeychainBackupService.backupProgress(context: modelContainer.mainContext)
            }
        }
    }

    @MainActor
    private func importAndRestore() async {
        let context = modelContainer.mainContext
        let service = DeckImportService(modelContext: context)

        let bundledDecks = [
            "ddia_consistency_models",
            "python_dsa",
            "ddia_chapter5_replication_v3",
            "ddia_chapter6_partitioning",
            "interview_linked_list",
            "interview_binary_tree",
            "interview_trie",
            "interview_graph",
            "interview_binary_search"
        ]

        // Get IDs of all currently installed decks
        let descriptor = FetchDescriptor<Deck>()
        let existingIDs = Set((try? context.fetch(descriptor))?.map(\.id) ?? [])

        // Pre-load all bundled JSON data off the main thread
        let deckData: [(String, Data)] = await Task.detached {
            bundledDecks.compactMap { name in
                guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
                      let data = try? Data(contentsOf: url) else { return nil }
                return (name, data)
            }
        }.value

        // Import bundled decks
        for (_, data) in deckData {
            guard let result = try? service.parseJSON(data) else { continue }
            if let deckId = result.deck.id, existingIDs.contains(deckId) { continue }
            _ = try? service.importDeck(result.deck, checkDuplicate: false)
        }

        // Restore user-imported decks from Keychain backup
        let updatedIDs = Set((try? context.fetch(descriptor))?.map(\.id) ?? [])
        for dto in KeychainBackupService.restoreDecks() {
            guard let deckId = dto.id, !updatedIDs.contains(deckId) else { continue }
            _ = try? service.importDeck(dto, checkDuplicate: false)
        }

        // Restore study progress from Keychain backup
        let progressBackups = KeychainBackupService.restoreProgress()
        if !progressBackups.isEmpty {
            let backupByScenario = Dictionary(progressBackups.map { ($0.scenarioID, $0) },
                                              uniquingKeysWith: { _, last in last })
            let scenarioDescriptor = FetchDescriptor<Scenario>()
            if let scenarios = try? context.fetch(scenarioDescriptor) {
                for scenario in scenarios {
                    guard let backup = backupByScenario[scenario.id],
                          let progress = scenario.userProgress,
                          progress.totalAttempts == 0 else { continue }
                    progress.easinessFactor = backup.easinessFactor
                    progress.interval = backup.interval
                    progress.repetitions = backup.repetitions
                    progress.nextReviewDate = backup.nextReviewDate
                    progress.lastReviewDate = backup.lastReviewDate
                    progress.totalAttempts = backup.totalAttempts
                    progress.correctAttempts = backup.correctAttempts
                    progress.lastConfidence = backup.lastConfidence
                    progress.masteryScore = backup.masteryScore
                }
                try? context.save()
            }
        }
    }
}
