import SwiftUI
import SwiftData

struct DeckDetailView: View {
    let deck: Deck
    @Environment(\.modelContext) private var modelContext
    @State private var showStudySession = false

    var body: some View {
        List {
            Section("Overview") {
                LabeledContent("Domain", value: deck.domain)
                LabeledContent("Scenarios", value: "\(deck.scenarios.count)")
                LabeledContent("Concepts", value: "\(deck.concepts.count)")
                LabeledContent("Version", value: deck.version)
            }

            Section("Mastery") {
                let stats = StatisticsService(modelContext: modelContext)
                let mastery = stats.deckMastery(deck)
                let dueCount = stats.dueCount(deckID: deck.id)

                HStack {
                    Text("Overall")
                    Spacer()
                    Text("\(Int(mastery * 100))%")
                        .fontWeight(.semibold)
                }
                HStack {
                    Text("Due for Review")
                    Spacer()
                    Text("\(dueCount)")
                        .foregroundStyle(dueCount > 0 ? .orange : .green)
                        .fontWeight(.semibold)
                }

                Button {
                    showStudySession = true
                } label: {
                    Label("Study This Deck", systemImage: "play.fill")
                }
            }

            Section("Concepts") {
                ForEach(deck.concepts) { concept in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(concept.name)
                            .font(.subheadline.bold())

                        let conceptMastery = conceptMasteryScore(concept)
                        ProgressBarView(progress: conceptMastery, color: conceptMastery >= 0.8 ? .green : .orange)

                        Text(concept.conceptDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Scenarios") {
                ForEach(deck.scenarios) { scenario in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(scenario.question)
                                .font(.subheadline)
                                .lineLimit(2)
                            HStack {
                                DifficultyBadge(difficulty: scenario.difficulty)
                                ForEach(scenario.tags.prefix(2), id: \.self) { tag in
                                    TagView(text: tag)
                                }
                            }
                        }
                        Spacer()
                        if let progress = scenario.userProgress, progress.totalAttempts > 0 {
                            Text("\(Int(progress.masteryScore * 100))%")
                                .font(.caption.bold())
                                .foregroundStyle(progress.masteryScore >= 0.8 ? .green : .orange)
                        } else {
                            Text("New")
                                .font(.caption.bold())
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle(deck.title)
        .fullScreenCover(isPresented: $showStudySession) {
            StudySessionView(deckID: deck.id, modelContext: modelContext)
        }
    }

    private func conceptMasteryScore(_ concept: Concept) -> Double {
        let related = deck.scenarios.filter { $0.conceptIDs.contains(concept.id) }
        let masteries = related.compactMap { $0.userProgress?.masteryScore }
        guard !masteries.isEmpty else { return 0 }
        return masteries.reduce(0, +) / Double(masteries.count)
    }
}
