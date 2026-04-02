import Foundation
import SwiftData

struct DTOMapper {
    static func mapDeck(from dto: DeckDTO) -> Deck {
        let deck = Deck(
            id: dto.id ?? UUID().uuidString,
            title: dto.title,
            deckDescription: dto.description,
            domain: dto.domain,
            version: dto.version ?? "1.0"
        )

        let concepts = dto.concepts.map { mapConcept(from: $0) }
        for concept in concepts {
            concept.deck = deck
        }
        deck.concepts = concepts

        let scenarios = dto.scenarios.map { mapScenario(from: $0) }
        for scenario in scenarios {
            scenario.deck = deck
        }
        deck.scenarios = scenarios

        return deck
    }

    static func mapConcept(from dto: ConceptDTO) -> Concept {
        Concept(
            id: dto.id,
            name: dto.name,
            conceptDescription: dto.description
        )
    }

    static func mapScenario(from dto: ScenarioDTO) -> Scenario {
        let scenario = Scenario(
            id: dto.id,
            type: ScenarioType(rawValue: dto.type) ?? .decision,
            difficulty: dto.difficulty,
            tags: dto.tags ?? [],
            conceptIDs: dto.concepts,
            context: dto.prompt.context,
            constraints: dto.prompt.constraints ?? [],
            question: dto.prompt.question,
            correctOptionID: dto.correctOptionId,
            reasoning: dto.explanation.reasoning,
            tradeoffs: dto.explanation.tradeoffs,
            keyTakeaway: dto.explanation.keyTakeaway,
            commonMistake: dto.explanation.commonMistake
        )

        let options = dto.options.map { mapOption(from: $0) }
        for option in options {
            option.scenario = scenario
        }
        scenario.options = options

        if let diagramDTO = dto.diagram {
            let diagramData = DiagramData(
                nodes: diagramDTO.nodes.map { DiagramNode(id: $0.id, label: $0.label, type: $0.type) },
                edges: diagramDTO.edges.map { DiagramEdge(from: $0.from, to: $0.to, label: $0.label) }
            )
            scenario.diagramDataJSON = try? JSONEncoder().encode(diagramData)
        }

        return scenario
    }

    static func mapOption(from dto: OptionDTO) -> Option {
        Option(
            id: dto.id,
            label: dto.label,
            optionDescription: dto.description
        )
    }
}
