import SwiftUI

struct ScenarioCardView: View {
    let scenario: Scenario

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                DifficultyBadge(difficulty: scenario.difficulty)
                Spacer()
                ForEach(scenario.tags.prefix(3), id: \.self) { tag in
                    TagView(text: tag)
                }
            }

            CodeAwareTextView(text: scenario.context, baseFont: .body)

            if !scenario.constraints.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Constraints")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    ForEach(scenario.constraints, id: \.self) { constraint in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 5))
                                .padding(.top, 6)
                                .foregroundStyle(.secondary)
                            Text(constraint)
                                .font(.callout)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            CodeAwareTextView(text: scenario.question, baseFont: .headline)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
