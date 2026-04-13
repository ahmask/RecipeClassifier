import FoundationModels

// MARK: - RecipeTaggingSession
//
// The content tagging adapter is a specialised version of the on-device model
// fine-tuned for extracting topics, entities, and tags from text.
//
// Instead of SystemLanguageModel.default (the general model),
// we use SystemLanguageModel(useCase: .contentTagging).
//
// In our app: when the user types a query, we extract dietary tags
// and key ingredients from it before classifying and generating the recipe.
// Example: "I want something spicy with chicken and no dairy"
// → dietaryTags: ["spicy", "dairy-free"], ingredients: ["chicken"]
//
// We keep this in a separate class because it uses a different model
// instance from the main recipe session.

import Observation
import FoundationModels

@Observable
@MainActor
class RecipeTaggingSession {

    var tags: RecipeTagResult?

    private var session: LanguageModelSession?

    init() {
        let model = SystemLanguageModel(useCase: .contentTagging)
        if case .available = model.availability {
            session = LanguageModelSession(
                model: model,
                instructions: "Extract dietary tags and key ingredients from cooking-related queries."
            )
        }
    }

    func extractTags(from query: String) async {
        guard let session else { return }
        tags = nil

        do {
            let response = try await session.respond(
                to: query,
                generating: RecipeTagResult.self
            )
            let result = response.content
            if !(result.dietaryTags.isEmpty && result.ingredients.isEmpty) {
                tags = result
            }
        } catch {
            // Tags are a bonus feature — fail silently
        }
    }
}
