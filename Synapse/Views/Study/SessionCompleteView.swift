import SwiftUI

struct SessionCompleteView: View {
    let session: StudySession?
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "trophy.fill")
                .font(.system(size: 64))
                .foregroundStyle(.yellow)

            Text("Session Complete!")
                .font(.title.bold())

            if let session {
                VStack(spacing: 16) {
                    statRow(label: "Scenarios", value: "\(session.totalScenarios)")
                    statRow(label: "Correct", value: "\(session.correctCount) / \(session.totalScenarios)")
                    statRow(label: "Accuracy", value: "\(Int(session.accuracy * 100))%")
                    if let duration = session.duration {
                        statRow(label: "Duration", value: formatDuration(duration))
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Spacer()

            Button {
                onDismiss()
            } label: {
                Text("Done")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
}
