import SwiftUI
import SwiftData

struct StreakCalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var studyDates: Set<DateComponents> = []

    private let calendar = Calendar.current
    private let daysToShow = 28

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Study Activity")
                .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                // Day headers
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }

                // Calendar cells
                ForEach(calendarDays, id: \.self) { date in
                    let components = calendar.dateComponents([.year, .month, .day], from: date)
                    let hasStudy = studyDates.contains(components)
                    let isToday = calendar.isDateInToday(date)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(cellColor(hasStudy: hasStudy, isToday: isToday))
                        .frame(height: 24)
                        .overlay {
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 9))
                                .foregroundStyle(hasStudy ? .white : .secondary)
                        }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            let stats = StatisticsService(modelContext: modelContext)
            studyDates = stats.studyDates(inLast: daysToShow)
        }
    }

    private var calendarDays: [Date] {
        let today = calendar.startOfDay(for: Date())
        // Find the start of the current week, then go back enough weeks
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        let start = calendar.date(byAdding: .day, value: -(daysToShow - 7), to: startOfWeek)!

        return (0..<daysToShow).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    private func cellColor(hasStudy: Bool, isToday: Bool) -> Color {
        if hasStudy { return .green }
        if isToday { return .blue.opacity(0.2) }
        return Color(.systemGroupedBackground)
    }
}
