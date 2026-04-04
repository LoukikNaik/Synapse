import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ImportView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var jsonText = ""
    @State private var importResult: ImportResult?
    @State private var errorMessage: String?
    @State private var showPreview = false
    @State private var showFileImporter = false
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    pasteSection
                    orDivider
                    fileImportSection

                    if let error = errorMessage {
                        errorBanner(error)
                    }

                    if showSuccess {
                        successBanner
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Import Deck")
            .sheet(isPresented: $showPreview) {
                if let result = importResult {
                    ImportPreviewView(
                        importResult: result,
                        onConfirm: { confirmImport(result.deck) },
                        onCancel: { showPreview = false }
                    )
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [UTType.json],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
        }
    }

    private var pasteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Paste JSON", systemImage: "doc.on.clipboard")
                .font(.headline)

            TextEditor(text: $jsonText)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 200)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
            Button {
                parseAndPreview(jsonText)
            } label: {
                Label("Parse & Preview", systemImage: "arrow.right.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(jsonText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private var orDivider: some View {
        HStack {
            Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 1)
            Text("OR")
                .font(.caption)
                .foregroundStyle(.secondary)
            Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 1)
        }
    }

    private var fileImportSection: some View {
        Button {
            showFileImporter = true
        } label: {
            Label("Import from File", systemImage: "folder.badge.plus")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.callout)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var successBanner: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("Deck imported successfully!")
                .font(.callout)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func parseAndPreview(_ text: String) {
        errorMessage = nil
        showSuccess = false
        let service = DeckImportService(modelContext: modelContext)
        do {
            let result = try service.parseJSON(text)
            importResult = result
            showPreview = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        errorMessage = nil
        showSuccess = false
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "Cannot access file"
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            do {
                let data = try Data(contentsOf: url)
                let service = DeckImportService(modelContext: modelContext)
                let importResult = try service.parseJSON(data)
                self.importResult = importResult
                showPreview = true
            } catch {
                errorMessage = error.localizedDescription
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func confirmImport(_ dto: DeckDTO) {
        let service = DeckImportService(modelContext: modelContext)
        do {
            _ = try service.importDeck(dto)
            KeychainBackupService.backupDeck(dto)
            showPreview = false
            showSuccess = true
            jsonText = ""
            importResult = nil
        } catch {
            showPreview = false
            errorMessage = error.localizedDescription
        }
    }
}
