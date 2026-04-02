import SwiftUI

struct ImportPreviewView: View {
    let importResult: ImportResult
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue)
                    Text(importResult.deck.title)
                        .font(.title2.bold())
                    Text(importResult.deck.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 12) {
                    previewRow(icon: "book.closed", label: "Domain", value: importResult.deck.domain)
                    previewRow(icon: "lightbulb", label: "Concepts", value: "\(importResult.conceptCount)")
                    previewRow(icon: "questionmark.circle", label: "Scenarios", value: "\(importResult.scenarioCount)")
                    previewRow(icon: "tag", label: "Version", value: importResult.deck.version ?? "1.0")
                }
                .padding()
                .background(Color(.systemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        onConfirm()
                    } label: {
                        Label("Import Deck", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button("Cancel", role: .cancel) {
                        onCancel()
                    }
                }
            }
            .padding()
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func previewRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}
