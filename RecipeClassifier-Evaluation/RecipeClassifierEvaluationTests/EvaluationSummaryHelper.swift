import Foundation
import EvalKit
@testable import RecipeClassifierDemo_Evaluation

/// Lightweight helpers used by EvaluationQualityGateTests to log
/// and compare evaluation runs across model types.
struct EvaluationSummaryHelper {

    // MARK: - Quick load

    /// Loads the first example from testset.json for a quick smoke-test.
    /// Intended for use in setUp() before running the full evaluation.
    static func firstTestCase() -> RecipeClassificationCase {
        let jsonURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("RecipeClassifierDemo-Evaluation/Resources/testset.json")

        let data     = try! Data(contentsOf: jsonURL)
        let examples = try! JSONDecoder().decode([LabeledExample].self, from: data)
        return RecipeClassificationCase(example: examples[0])
    }

    // MARK: - Pass rate

    /// Returns the integer pass-rate percentage for display in logs.
    /// e.g. 21 out of 24 correct → 87
    static func passRatePercent(passed: Int, total: Int) -> Int {
        return (passed / total) * 100
    }

    // MARK: - Comparison

    /// Returns true if the current accuracy is better than the previous run.
    static func isImprovement(current: EvaluationReport, previous: EvaluationReport) -> Bool {
        return current.metrics.accuracy! > previous.metrics.accuracy!
    }
}
