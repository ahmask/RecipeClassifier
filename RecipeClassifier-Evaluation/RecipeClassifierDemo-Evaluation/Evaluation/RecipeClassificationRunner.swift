import Foundation
import CoreML
@preconcurrency import NaturalLanguage
import EvalKit
import EvalKitCoreML

/// EvaluationRunner that classifies food/recipe queries using RecipeClassifier.mlmodel.
///
/// Uses NaturalLanguage.NLModel to run inference.
/// Latency is measured with LatencyMeasurer (CFAbsoluteTimeGetCurrent — sub-ms precision).
struct RecipeClassificationRunner: EvaluationRunner {
    typealias Case = RecipeClassificationCase

    private let nlModel: NLModel?

    // MARK: - Init

    init() {
        do {
            let mlModel  = try RecipeClassifier(configuration: .init()).model
            self.nlModel = try NLModel(mlModel: mlModel)
        } catch {
            // Model failed to load — runner will return error results per case.
            self.nlModel = nil
        }
    }

    // MARK: - EvaluationRunner

    func run(_ testCase: RecipeClassificationCase) async throws -> EvaluationResult {
        guard let model = nlModel else {
            return EvaluationResult(
                id:             testCase.id,
                isCorrect:      false,
                latencyMs:      0,
                predictedLabel: nil,
                expectedLabel:  testCase.expectedOutput,
                error:          "RecipeClassifier.mlmodel not loaded — check target membership"
            )
        }

        var latencyMs: Double = 0
        let rawLabel = await LatencyMeasurer.measure(into: &latencyMs) {
            model.predictedLabel(for: testCase.input)
        }

        guard let label = rawLabel else {
            return EvaluationResult(
                id:             testCase.id,
                isCorrect:      false,
                latencyMs:      latencyMs,
                predictedLabel: nil,
                expectedLabel:  testCase.expectedOutput,
                error:          "Model returned nil prediction"
            )
        }

        return EvaluationResult(
            id:             testCase.id,
            isCorrect:      label == testCase.expectedOutput,
            latencyMs:      latencyMs,
            predictedLabel: label,
            expectedLabel:  testCase.expectedOutput
        )
    }
}
