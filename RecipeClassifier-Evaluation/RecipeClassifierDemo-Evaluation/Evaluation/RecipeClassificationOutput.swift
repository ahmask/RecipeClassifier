import Foundation
import FoundationModels

/// Structured output type for the Foundation Models LLM evaluation path.
///
/// @Generable expands at compile time to add Codable conformance and a
/// JSON schema. The @Guide .anyOf constraint limits the model's output to
/// exactly the 8 valid food category raw values — eliminating hallucinations
/// at the schema level before a single token is generated.
///
/// Requires iOS 26+ with Apple Intelligence available. All call sites are
/// guarded with @available(iOS 26.0, *).
@available(iOS 26.0, *)
@Generable
struct RecipeClassificationOutput {

    @Guide(
        description: "The cuisine or meal category that best matches the query.",
        .anyOf(FoodCategory.allCases.map(\.rawValue))
    )
    var category: String

    @Guide(description: "One sentence explaining why this category was chosen.")
    var reasoning: String
}
