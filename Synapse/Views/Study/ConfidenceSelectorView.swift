import SwiftUI

struct ConfidenceSelectorView: View {
    @Binding var confidence: Confidence

    var body: some View {
        VStack(spacing: 8) {
            Text("How confident are you?")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker("Confidence", selection: $confidence) {
                ForEach(Confidence.allCases, id: \.self) { level in
                    Text(level.label).tag(level)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
