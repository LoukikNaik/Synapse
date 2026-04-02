import SwiftUI
import SwiftData

struct DeckLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Deck.importedAt, order: .reverse) private var decks: [Deck]
    @State private var deckToDelete: Deck?
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            Group {
                if decks.isEmpty {
                    ContentUnavailableView(
                        "No Decks",
                        systemImage: "books.vertical",
                        description: Text("Import a deck from the Import tab to get started.")
                    )
                } else {
                    List {
                        ForEach(decks) { deck in
                            NavigationLink(destination: DeckDetailView(deck: deck)) {
                                DeckRowView(deck: deck)
                            }
                        }
                        .onDelete { indexSet in
                            if let index = indexSet.first {
                                deckToDelete = decks[index]
                                showDeleteConfirmation = true
                            }
                        }
                    }
                }
            }
            .navigationTitle("Library")
            .confirmationDialog(
                "Delete Deck",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let deck = deckToDelete {
                        modelContext.delete(deck)
                        try? modelContext.save()
                    }
                    deckToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    deckToDelete = nil
                }
            } message: {
                Text("Are you sure you want to delete \"\(deckToDelete?.title ?? "")\"? This will remove all scenarios and progress.")
            }
        }
    }
}
