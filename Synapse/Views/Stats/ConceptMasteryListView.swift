import SwiftUI
import SwiftData

struct ConceptMasteryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var concepts: [Concept]

    var body: some View {
        if concepts.isEmpty {
            Text("No concepts yet")
                .foregroundStyle(.secondary)
        } else {
            ForEach(sortedConcepts, id: \.concept.id) { item in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.concept.name)
                            .font(.subheadline)
                        ProgressBarView(
                            progress: item.mastery,
                            color: item.mastery >= 0.8 ? .green : (item.mastery >= 0.5 ? .orange : .red)
                        )
                    }
                    Spacer()
                    Text("\(Int(item.mastery * 100))%")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var sortedConcepts: [(concept: Concept, mastery: Double)] {
        concepts.map { concept in
            let descriptor = FetchDescriptor<Scenario>()
            let scenarios = (try? modelContext.fetch(descriptor)) ?? []
            let related = scenarios.filter { $0.conceptIDs.contains(concept.id) }
            let masteries = related.compactMap { $0.userProgress?.masteryScore }
            let avg = masteries.isEmpty ? 0.0 : masteries.reduce(0, +) / Double(masteries.count)
            return (concept: concept, mastery: avg)
        }.sorted { $0.mastery > $1.mastery }
    }
}
