import XCTest
@testable import Synapse

final class DTOMapperTests: XCTestCase {

    func testMapConcept() {
        let dto = ConceptDTO(id: "c1", name: "Test Concept", description: "A test")
        let concept = DTOMapper.mapConcept(from: dto)

        XCTAssertEqual(concept.id, "c1")
        XCTAssertEqual(concept.name, "Test Concept")
        XCTAssertEqual(concept.conceptDescription, "A test")
    }

    func testMapOption() {
        let dto = OptionDTO(id: "o1", label: "Option A", description: "First option")
        let option = DTOMapper.mapOption(from: dto)

        XCTAssertEqual(option.id, "o1")
        XCTAssertEqual(option.label, "Option A")
        XCTAssertEqual(option.optionDescription, "First option")
    }

    func testMapScenario() {
        let dto = ScenarioDTO(
            id: "s1",
            type: "decision",
            difficulty: 3,
            tags: ["tag1"],
            concepts: ["c1"],
            prompt: PromptDTO(context: "Test context", constraints: ["constraint1"], question: "What?"),
            options: [
                OptionDTO(id: "o1", label: "A", description: "Option A"),
                OptionDTO(id: "o2", label: "B", description: "Option B")
            ],
            correctOptionId: "o1",
            explanation: ExplanationDTO(
                reasoning: "Because",
                tradeoffs: "Tradeoff",
                keyTakeaway: "Takeaway",
                commonMistake: "Mistake"
            )
        )

        let scenario = DTOMapper.mapScenario(from: dto)

        XCTAssertEqual(scenario.id, "s1")
        XCTAssertEqual(scenario.type, .decision)
        XCTAssertEqual(scenario.difficulty, 3)
        XCTAssertEqual(scenario.tags, ["tag1"])
        XCTAssertEqual(scenario.conceptIDs, ["c1"])
        XCTAssertEqual(scenario.context, "Test context")
        XCTAssertEqual(scenario.constraints, ["constraint1"])
        XCTAssertEqual(scenario.question, "What?")
        XCTAssertEqual(scenario.options.count, 2)
        XCTAssertEqual(scenario.correctOptionID, "o1")
        XCTAssertEqual(scenario.reasoning, "Because")
        XCTAssertEqual(scenario.keyTakeaway, "Takeaway")
    }

    func testMapScenarioWithDiagram() {
        let dto = ScenarioDTO(
            id: "s2",
            type: "diagram",
            difficulty: 4,
            tags: nil,
            concepts: [],
            prompt: PromptDTO(context: "Diagram context", constraints: nil, question: "Which?"),
            options: [
                OptionDTO(id: "o1", label: "A", description: "A"),
                OptionDTO(id: "o2", label: "B", description: "B")
            ],
            correctOptionId: "o2",
            explanation: ExplanationDTO(reasoning: "R", tradeoffs: "T", keyTakeaway: "K", commonMistake: "M"),
            diagram: DiagramDTO(
                nodes: [
                    DiagramNodeDTO(id: "n1", label: "Node 1", type: "primary"),
                    DiagramNodeDTO(id: "n2", label: "Node 2", type: nil)
                ],
                edges: [
                    DiagramEdgeDTO(from: "n1", to: "n2", label: "connects")
                ]
            )
        )

        let scenario = DTOMapper.mapScenario(from: dto)

        XCTAssertEqual(scenario.type, .diagram)
        XCTAssertNotNil(scenario.diagramDataJSON)

        let diagramData = scenario.decodedDiagramData
        XCTAssertNotNil(diagramData)
        XCTAssertEqual(diagramData?.nodes.count, 2)
        XCTAssertEqual(diagramData?.edges.count, 1)
        XCTAssertEqual(diagramData?.edges.first?.label, "connects")
    }

    func testMapDeck() {
        let dto = DeckDTO(
            id: "d1",
            title: "Test Deck",
            description: "A test deck",
            domain: "testing",
            version: "1.0",
            concepts: [
                ConceptDTO(id: "c1", name: "Concept", description: "Desc")
            ],
            scenarios: [
                ScenarioDTO(
                    id: "s1",
                    type: "decision",
                    difficulty: 2,
                    tags: nil,
                    concepts: ["c1"],
                    prompt: PromptDTO(context: "C", constraints: nil, question: "Q"),
                    options: [
                        OptionDTO(id: "o1", label: "A", description: "A"),
                        OptionDTO(id: "o2", label: "B", description: "B")
                    ],
                    correctOptionId: "o1",
                    explanation: ExplanationDTO(reasoning: "R", tradeoffs: "T", keyTakeaway: "K", commonMistake: "M")
                )
            ]
        )

        let deck = DTOMapper.mapDeck(from: dto)

        XCTAssertEqual(deck.id, "d1")
        XCTAssertEqual(deck.title, "Test Deck")
        XCTAssertEqual(deck.concepts.count, 1)
        XCTAssertEqual(deck.scenarios.count, 1)
        XCTAssertEqual(deck.scenarios.first?.deck?.id, deck.id)
        XCTAssertEqual(deck.concepts.first?.deck?.id, deck.id)
    }
}
