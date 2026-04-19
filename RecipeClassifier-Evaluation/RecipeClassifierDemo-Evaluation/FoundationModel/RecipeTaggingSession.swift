import Observation
import FoundationModels

// MARK: - RecipeTaggingSession
//
// Uses SystemLanguageModel(useCase: .contentTagging) — a specialised
// fine-tuned model for extracting topics, entities, and tags from text.
// Runs in parallel with the main classify + stream flow.
//
// Example: "I want something spicy with chicken and no dairy"
// → dietaryTags: ["spicy", "dairy-free"], ingredients: ["chicken"]

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
            // Tags are a bonus feature — fail silently.
        }
    }
}
