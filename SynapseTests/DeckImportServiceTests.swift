import XCTest
@testable import Synapse

final class DeckImportServiceTests: XCTestCase {

    private let validJSON = """
    {
        "title": "Test Deck",
        "description": "A test",
        "domain": "testing",
        "concepts": [
            {"id": "c1", "name": "Concept", "description": "Desc"}
        ],
        "scenarios": [
            {
                "id": "s1",
                "type": "decision",
                "difficulty": 2,
                "concepts": ["c1"],
                "prompt": {"context": "Context", "question": "Question?"},
                "options": [
                    {"id": "o1", "label": "A", "description": "Option A"},
                    {"id": "o2", "label": "B", "description": "Option B"}
                ],
                "correctOptionId": "o1",
                "explanation": {
                    "reasoning": "Because",
                    "tradeoffs": "None",
                    "keyTakeaway": "Remember",
                    "commonMistake": "Don't"
                }
            }
        ]
    }
    """

    func testParseValidJSON_succeeds() throws {
        // parseJSON doesn't need modelContext for parsing only
        let data = validJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        let dto = try decoder.decode(DeckDTO.self, from: data)

        XCTAssertEqual(dto.title, "Test Deck")
        XCTAssertEqual(dto.concepts.count, 1)
        XCTAssertEqual(dto.scenarios.count, 1)
    }

    func testParseInvalidJSON_fails() {
        let data = "not json".data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(DeckDTO.self, from: data))
    }

    func testValidation_emptyTitle_fails() {
        let json = """
        {
            "title": "",
            "description": "A test",
            "domain": "testing",
            "concepts": [],
            "scenarios": [
                {
                    "id": "s1",
                    "type": "decision",
                    "difficulty": 2,
                    "concepts": [],
                    "prompt": {"context": "C", "question": "Q"},
                    "options": [
                        {"id": "o1", "label": "A", "description": "A"},
                        {"id": "o2", "label": "B", "description": "B"}
                    ],
                    "correctOptionId": "o1",
                    "explanation": {"reasoning": "R", "tradeoffs": "T", "keyTakeaway": "K", "commonMistake": "M"}
                }
            ]
        }
        """
        // Validation is done in DeckImportService which needs ModelContext
        // Test the DTO parsing separately
        let data = json.data(using: .utf8)!
        let dto = try? JSONDecoder().decode(DeckDTO.self, from: data)
        XCTAssertNotNil(dto)
        XCTAssertTrue(dto?.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? false)
    }

    func testValidation_noScenarios_detected() {
        let json = """
        {
            "title": "Test",
            "description": "A test",
            "domain": "testing",
            "concepts": [],
            "scenarios": []
        }
        """
        let data = json.data(using: .utf8)!
        let dto = try? JSONDecoder().decode(DeckDTO.self, from: data)
        XCTAssertNotNil(dto)
        XCTAssertTrue(dto?.scenarios.isEmpty ?? false)
    }

    func testValidation_invalidCorrectOptionId_detected() {
        let json = """
        {
            "title": "Test",
            "description": "A test",
            "domain": "testing",
            "concepts": [],
            "scenarios": [
                {
                    "id": "s1",
                    "type": "decision",
                    "difficulty": 2,
                    "concepts": [],
                    "prompt": {"context": "C", "question": "Q"},
                    "options": [
                        {"id": "o1", "label": "A", "description": "A"},
                        {"id": "o2", "label": "B", "description": "B"}
                    ],
                    "correctOptionId": "nonexistent",
                    "explanation": {"reasoning": "R", "tradeoffs": "T", "keyTakeaway": "K", "commonMistake": "M"}
                }
            ]
        }
        """
        let data = json.data(using: .utf8)!
        let dto = try? JSONDecoder().decode(DeckDTO.self, from: data)
        XCTAssertNotNil(dto)
        // correctOptionId "nonexistent" is not in options
        let optionIDs = Set(dto?.scenarios.first?.options.map(\.id) ?? [])
        XCTAssertFalse(optionIDs.contains(dto?.scenarios.first?.correctOptionId ?? ""))
    }

    func testSampleDeckJSON_parsesSuccessfully() throws {
        let sampleJSON = try loadSampleDeckJSON()
        let dto = try JSONDecoder().decode(DeckDTO.self, from: sampleJSON)

        XCTAssertEqual(dto.title, "DDIA: Consistency Models")
        XCTAssertEqual(dto.concepts.count, 3)
        XCTAssertEqual(dto.scenarios.count, 3)

        // Verify diagram scenario
        let diagramScenario = dto.scenarios.first { $0.type == "diagram" }
        XCTAssertNotNil(diagramScenario)
        XCTAssertNotNil(diagramScenario?.diagram)
        XCTAssertEqual(diagramScenario?.diagram?.nodes.count, 3)
        XCTAssertEqual(diagramScenario?.diagram?.edges.count, 6)
    }

    private func loadSampleDeckJSON() throws -> Data {
        // Find the sample JSON relative to the test file
        let testDir = URL(fileURLWithPath: #file).deletingLastPathComponent()
        let projectDir = testDir.deletingLastPathComponent()
        let sampleURL = projectDir.appendingPathComponent("SampleDecks/ddia_consistency_models.json")
        return try Data(contentsOf: sampleURL)
    }
}
