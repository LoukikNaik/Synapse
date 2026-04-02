import Foundation
import SwiftData

@Model
final class Option {
    @Attribute(.unique) var id: String
    var label: String
    var optionDescription: String
    var scenario: Scenario?

    init(
        id: String = UUID().uuidString,
        label: String,
        optionDescription: String
    ) {
        self.id = id
        self.label = label
        self.optionDescription = optionDescription
    }
}
