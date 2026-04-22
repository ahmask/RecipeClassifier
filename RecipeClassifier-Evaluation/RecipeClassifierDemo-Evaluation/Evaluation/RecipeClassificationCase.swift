import Foundation
import EvalKit

/// Wraps one row from the labeled test dataset into the EvaluationCase protocol.
/// `input` is the raw text; `expectedOutput` is the FoodCategory raw value string.
struct RecipeClassificationCase: EvaluationCase {
    let id: String
    let input: String
    let expectedOutput: String

    init(example: LabeledExample) {
        self.id             = "\(example.id)"
        self.input          = example.text
        self.expectedOutput = example.label
    }
}
