import Foundation
import SwiftData

enum ImportError: LocalizedError {
    case invalidJSON(String)
    case duplicateDeck(String)
    case validationFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidJSON(let detail): return "Invalid JSON: \(detail)"
        case .duplicateDeck(let title): return "Deck '\(title)' already exists"
        case .validationFailed(let detail): return "Validation failed: \(detail)"
        }
    }
}

struct ImportResult {
    let deck: DeckDTO
    let conceptCount: Int
    let scenarioCount: Int
}

@MainActor
final class DeckImportService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func parseJSON(_ jsonString: String) throws -> ImportResult {
        guard let data = jsonString.data(using: .utf8) else {
            throw ImportError.invalidJSON("Could not encode string as UTF-8")
        }
        return try parseJSON(data)
    }

    func parseJSON(_ data: Data) throws -> ImportResult {
        let decoder = JSONDecoder()
        let deckDTO: DeckDTO
        do {
            deckDTO = try decoder.decode(DeckDTO.self, from: data)
        } catch {
            throw ImportError.invalidJSON(error.localizedDescription)
        }

        try validate(deckDTO)
        return ImportResult(
            deck: deckDTO,
            conceptCount: deckDTO.concepts.count,
            scenarioCount: deckDTO.scenarios.count
        )
    }

    func importDeck(_ dto: DeckDTO, checkDuplicate: Bool = true) throws -> Deck {
        if checkDuplicate {
            let title = dto.title
            let descriptor = FetchDescriptor<Deck>(
                predicate: #Predicate { $0.title == title }
            )
            let existing = try modelContext.fetch(descriptor)
            if !existing.isEmpty {
                throw ImportError.duplicateDeck(dto.title)
            }
        }

        let deck = DTOMapper.mapDeck(from: dto)
        modelContext.insert(deck)

        // Create UserProgress for each scenario
        for scenario in deck.scenarios {
            let progress = UserProgress(id: UUID().uuidString)
            progress.scenario = scenario
            scenario.userProgress = progress
            modelContext.insert(progress)
        }

        try modelContext.save()
        return deck
    }

    private func validate(_ dto: DeckDTO) throws {
        if dto.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ImportError.validationFailed("Deck title is required")
        }
        if dto.scenarios.isEmpty {
            throw ImportError.validationFailed("Deck must have at least one scenario")
        }

        let conceptIDs = Set(dto.concepts.map(\.id))
        for scenario in dto.scenarios {
            if scenario.options.count < 2 {
                throw ImportError.validationFailed(
                    "Scenario '\(scenario.id)' must have at least 2 options"
                )
            }
            let optionIDs = Set(scenario.options.map(\.id))
            if !optionIDs.contains(scenario.correctOptionId) {
                throw ImportError.validationFailed(
                    "Scenario '\(scenario.id)' correctOptionId '\(scenario.correctOptionId)' not found in options"
                )
            }
            for conceptRef in scenario.concepts {
                if !conceptIDs.contains(conceptRef) {
                    throw ImportError.validationFailed(
                        "Scenario '\(scenario.id)' references unknown concept '\(conceptRef)'"
                    )
                }
            }
        }
    }
}
