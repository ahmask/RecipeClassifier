import Foundation
import FoundationModels
import EvalKit

/// EvaluationRunner for the Apple Foundation Models path.
///
/// Creates a fresh LanguageModelSession per test case so that no context
/// accumulates across the evaluation batch. Reusing a session would let the
/// model use the history of prior queries, which contaminates per-case results.
///
/// Uses @Generable structured output (RecipeClassificationOutput) so the model
/// schema enforces valid category strings. This is what produces a 0 %
/// hallucination rate — the model cannot generate a string outside the
/// .anyOf vocabulary defined in RecipeClassificationOutput.category.
///
/// Requires iOS 26+ with Apple Intelligence available.
@available(iOS 26.0, *)
struct RecipeLLMRunner: EvaluationRunner, Sendable {
    typealias Case = RecipeClassificationCase

    // MARK: - System prompt

    private static let instructions = """
        Classify the user's cooking or recipe query into exactly one of these 8 categories:

          italian       — Italian cuisine: pasta, pizza, risotto, tiramisu, etc.
          mexican       — Mexican cuisine: tacos, guacamole, enchiladas, salsa, etc.
          asian         — Asian cuisine: ramen, sushi, stir-fry, pad thai, kimchi, etc.
          american      — American food: burgers, BBQ, mac and cheese, fried chicken, etc.
          mediterranean — Mediterranean food: hummus, falafel, shakshuka, Greek salad, etc.
          breakfast     — Breakfast dishes: pancakes, eggs, granola, avocado toast, etc.
          dessert       — Desserts and sweets: cakes, cookies, chocolate, ice cream, etc.
          other         — General cooking questions, kitchen tips, or unrelated queries

        Return the category string exactly as shown above, lowercase.
        """

    // MARK: - EvaluationRunner

    func run(_ testCase: RecipeClassificationCase) async throws -> EvaluationResult {
        // Fresh session per case — no context bleed between queries.
        let session = LanguageModelSession(instructions: Self.instructions)
        let start   = CFAbsoluteTimeGetCurrent()

        do {
            let response  = try await session.respond(
                to:         testCase.input,
                generating: RecipeClassificationOutput.self
            )
            let latencyMs = (CFAbsoluteTimeGetCurrent() - start) * 1_000
            let output    = response.content

            // @Generable .anyOf already constrains the vocabulary, so
            // parsed == nil means an unexpected schema mismatch (extremely rare).
            let parsed    = FoodCategory(rawValue: output.category)
            let predicted = parsed?.rawValue

            return EvaluationResult(
                id:                testCase.id,
                isCorrect:         predicted == testCase.expectedOutput,
                latencyMs:         latencyMs,
                predictedLabel:    predicted,
                expectedLabel:     testCase.expectedOutput,
                hallucinationFlag: parsed == nil,
                reasoning:         output.reasoning
            )
        } catch {
            let latencyMs = (CFAbsoluteTimeGetCurrent() - start) * 1_000
            return EvaluationResult(
                id:            testCase.id,
                isCorrect:     false,
                latencyMs:     latencyMs,
                expectedLabel: testCase.expectedOutput,
                error:         error.localizedDescription
            )
        }
    }
}
