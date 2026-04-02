import SwiftUI
import SwiftData

struct DeckRowView: View {
    let deck: Deck
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(deck.title)
                    .font(.headline)
                Spacer()
                Text("\(Int(mastery * 100))%")
                    .font(.caption.bold())
                    .foregroundStyle(masteryColor)
            }

            Text(deck.deckDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack {
                Label("\(deck.scenarios.count) scenarios", systemImage: "questionmark.circle")
                Spacer()
                Label("\(deck.concepts.count) concepts", systemImage: "lightbulb")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)

            ProgressBarView(progress: mastery, color: masteryColor)
        }
        .padding(.vertical, 4)
    }

    private var mastery: Double {
        StatisticsService(modelContext: modelContext).deckMastery(deck)
    }

    private var masteryColor: Color {
        if mastery >= 0.8 { return .green }
        if mastery >= 0.5 { return .orange }
        return .red
    }
}
