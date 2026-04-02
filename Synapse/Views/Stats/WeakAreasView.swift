import SwiftUI
import SwiftData

struct WeakAreasView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var weakConcepts: [(concept: Concept, mastery: Double)] = []

    var body: some View {
        Group {
            if weakConcepts.isEmpty {
                Text("No weak areas identified yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(weakConcepts, id: \.concept.id) { item in
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.concept.name)
                                .font(.subheadline)
                            Text("\(Int(item.mastery * 100))% mastery")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        ProgressBarView(
                            progress: item.mastery,
                            color: .red
                        )
                        .frame(width: 60)
                    }
                }
            }
        }
        .onAppear {
            let stats = StatisticsService(modelContext: modelContext)
            weakConcepts = stats.weakConcepts(limit: 5)
        }
    }
}
