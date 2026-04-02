import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var decks: [Deck]
    @State private var showStudySession = false
    @State private var dueCount = 0
    @State private var newCount = 0
    @State private var overallMastery: Double = 0
    @State private var streak = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Mastery Ring
                    MasteryRingView(mastery: overallMastery)
                        .frame(height: 200)

                    // Due count + Study button
                    VStack(spacing: 12) {
                        HStack(spacing: 24) {
                            statCard(value: "\(dueCount)", label: "Due", color: .orange)
                            statCard(value: "\(newCount)", label: "New", color: .blue)
                            statCard(value: "\(streak)", label: "Streak", color: .green)
                        }

                        Button {
                            showStudySession = true
                        } label: {
                            Label("Start Study Session", systemImage: "play.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(dueCount + newCount == 0)
                    }

                    // Streak calendar
                    StreakCalendarView()
                }
                .padding()
            }
            .navigationTitle("Synapse")
            .onAppear { refreshStats() }
            .fullScreenCover(isPresented: $showStudySession) {
                StudySessionView(modelContext: modelContext)
                    .onDisappear { refreshStats() }
            }
        }
    }

    private func statCard(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func refreshStats() {
        let stats = StatisticsService(modelContext: modelContext)
        dueCount = stats.dueCount()
        newCount = stats.newCount()
        overallMastery = stats.overallMastery()
        streak = stats.currentStreak()
    }
}
