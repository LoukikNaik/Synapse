import SwiftUI
import SwiftData

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var overallMastery: Double = 0
    @State private var totalSessions: Int = 0
    @State private var streak: Int = 0

    var body: some View {
        NavigationStack {
            List {
                Section("Overview") {
                    HStack {
                        Label("Overall Mastery", systemImage: "chart.pie.fill")
                        Spacer()
                        Text("\(Int(overallMastery * 100))%")
                            .fontWeight(.bold)
                            .foregroundStyle(overallMastery >= 0.8 ? .green : .orange)
                    }
                    HStack {
                        Label("Total Sessions", systemImage: "clock.fill")
                        Spacer()
                        Text("\(totalSessions)")
                            .fontWeight(.bold)
                    }
                    HStack {
                        Label("Current Streak", systemImage: "flame.fill")
                        Spacer()
                        Text("\(streak) days")
                            .fontWeight(.bold)
                            .foregroundStyle(.orange)
                    }
                }

                Section("Weak Areas") {
                    WeakAreasView()
                }

                Section("Concept Mastery") {
                    ConceptMasteryListView()
                }
            }
            .navigationTitle("Statistics")
            .onAppear { refreshStats() }
        }
    }

    private func refreshStats() {
        let stats = StatisticsService(modelContext: modelContext)
        overallMastery = stats.overallMastery()
        totalSessions = stats.totalSessions()
        streak = stats.currentStreak()
    }
}
