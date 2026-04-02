import SwiftUI

struct DecisionOptionsView: View {
    let options: [Option]
    @Binding var selectedID: String?

    var body: some View {
        VStack(spacing: 10) {
            ForEach(options) { option in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedID = option.id
                    }
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: selectedID == option.id ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(selectedID == option.id ? .blue : .secondary)

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
                            .fill(selectedID == option.id
                                  ? Color.blue.opacity(0.1)
                                  : Color(.secondarySystemGroupedBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(selectedID == option.id ? Color.blue : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
