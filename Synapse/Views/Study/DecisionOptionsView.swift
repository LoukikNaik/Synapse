import SwiftUI

struct DecisionOptionsView: View {
    let options: [Option]
    @Binding var selectedID: String?
    var correctOptionID: String? = nil
    var isDisabled: Bool = false

    var body: some View {
        VStack(spacing: 10) {
            ForEach(options) { option in
                Button {
                    if !isDisabled {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedID = option.id
                        }
                    }
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: iconName(for: option))
                            .font(.title3)
                            .foregroundStyle(iconColor(for: option))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(option.label)
                                .font(.subheadline.bold())
                                .foregroundStyle(.primary)
                            Text(option.optionDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(backgroundColor(for: option))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(borderColor(for: option), lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
                .allowsHitTesting(!isDisabled)
            }
        }
    }

    private func iconName(for option: Option) -> String {
        if let correctID = correctOptionID {
            if option.id == correctID { return "checkmark.circle.fill" }
            if option.id == selectedID { return "xmark.circle.fill" }
            return "circle"
        }
        return selectedID == option.id ? "checkmark.circle.fill" : "circle"
    }

    private func iconColor(for option: Option) -> Color {
        if let correctID = correctOptionID {
            if option.id == correctID { return .green }
            if option.id == selectedID { return .red }
            return .secondary.opacity(0.5)
        }
        return selectedID == option.id ? .blue : .secondary
    }

    private func backgroundColor(for option: Option) -> Color {
        if let correctID = correctOptionID {
            if option.id == correctID { return Color.green.opacity(0.1) }
            if option.id == selectedID { return Color.red.opacity(0.1) }
            return Color(.secondarySystemGroupedBackground).opacity(0.5)
        }
        return selectedID == option.id ? Color.blue.opacity(0.1) : Color(.secondarySystemGroupedBackground)
    }

    private func borderColor(for option: Option) -> Color {
        if let correctID = correctOptionID {
            if option.id == correctID { return .green }
            if option.id == selectedID { return .red }
            return .clear
        }
        return selectedID == option.id ? .blue : .clear
    }
}
