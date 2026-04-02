import SwiftUI

struct FeedbackView: View {
    let scenario: Scenario
    let selectedOptionID: String?
    let isCorrect: Bool
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Result banner
            HStack {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title)
                Text(isCorrect ? "Correct!" : "Incorrect")
                    .font(.title2.bold())
            }
            .foregroundStyle(isCorrect ? .green : .red)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
            .background((isCorrect ? Color.green : Color.red).opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Your answer vs correct
            if !isCorrect, let selectedID = selectedOptionID {
                if let selected = scenario.options.first(where: { $0.id == selectedID }) {
                    feedbackSection(title: "Your Answer", icon: "xmark.circle", color: .red) {
                        Text(selected.label)
                            .font(.subheadline.bold())
                    }
                }
                if let correct = scenario.options.first(where: { $0.id == scenario.correctOptionID }) {
                    feedbackSection(title: "Correct Answer", icon: "checkmark.circle", color: .green) {
                        Text(correct.label)
                            .font(.subheadline.bold())
                    }
                }
            }

            feedbackSection(title: "Reasoning", icon: "brain") {
                CodeAwareTextView(text: scenario.reasoning)
            }

            feedbackSection(title: "Tradeoffs", icon: "arrow.left.arrow.right") {
                CodeAwareTextView(text: scenario.tradeoffs)
            }

            feedbackSection(title: "Key Takeaway", icon: "lightbulb.fill") {
                CodeAwareTextView(text: scenario.keyTakeaway)
            }

            feedbackSection(title: "Common Mistake", icon: "exclamationmark.triangle") {
                CodeAwareTextView(text: scenario.commonMistake)
            }

            Button {
                onContinue()
            } label: {
                Label("Continue", systemImage: "arrow.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private func feedbackSection<Content: View>(
        title: String,
        icon: String,
        color: Color = .primary,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption.bold())
                .foregroundStyle(color)
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
