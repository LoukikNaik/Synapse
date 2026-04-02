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
                    await autoImportSampleDeckIfNeeded()
                    isImporting = false
                }
            } else {
                MainTabView()
            }
        }
        .modelContainer(modelContainer)
    }

    @MainActor
    private func autoImportSampleDeckIfNeeded() async {
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

        // Pre-load all JSON data off the main thread
        let deckData: [(String, Data)] = await Task.detached {
            bundledDecks.compactMap { name in
                guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
                      let data = try? Data(contentsOf: url) else { return nil }
                return (name, data)
            }
        }.value

        // Parse and import on main context (required by SwiftData)
        for (_, data) in deckData {
            guard let result = try? service.parseJSON(data) else { continue }
            if let deckId = result.deck.id, existingIDs.contains(deckId) { continue }
            _ = try? service.importDeck(result.deck, checkDuplicate: false)
        }
    }
}
