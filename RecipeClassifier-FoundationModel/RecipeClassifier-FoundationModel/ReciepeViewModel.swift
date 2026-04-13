import SwiftUI
import FoundationModels

@Observable
@MainActor
class RecipeViewModel {

    // Classification result — appears instantly, just like the CoreML demo
    var classification: RecipeClassification?

    // Streaming recipe — fills in progressively after classification
    var recipeDetail: RecipeDetail.PartiallyGenerated?

    var isAvailable: Bool = false
    var isLoading: Bool = false
    var errorMessage: String?

    private var session: LanguageModelSession?

    init() {
        setupSession()
    }

    // MARK: - Setup

    private func setupSession() {
        switch SystemLanguageModel.default.availability {
        case .available:
            isAvailable = true
            session = LanguageModelSession(
                tools: [GetRecipeDetailsTool()],
                instructions: """
                    You are a friendly and knowledgeable cooking assistant.
                    When the user asks about a recipe or how to make a dish,
                    always use the getRecipeDetails tool to fetch the full recipe.
                    Keep your responses focused on cooking and food.
                    Be warm, encouraging, and enthusiastic about cooking.
                    If the user asks a follow-up like "make it vegetarian" or
                    "make it spicier", adapt the previous recipe accordingly
                    and call getRecipeDetails again with the updated dish name.
                    """
            )
        case .unavailable(let reason):
            isAvailable = false
            errorMessage = unavailabilityMessage(for: reason)
        }
    }

    // MARK: - Public API

    func ask(query: String) async {
        guard let session else { return }
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        isLoading = true
        classification = nil
        recipeDetail = nil
        errorMessage = nil

        do {
            // Step 1 — Classify the cuisine instantly (same feel as the CoreML demo)
            // This is a single fast respond() call, not streaming.
            let classifyResponse = try await session.respond(
                to: trimmed,
                generating: RecipeClassification.self
            )
            classification = classifyResponse.content

            // Step 2 — Stream the full recipe details
            // The session remembers the classification exchange above,
            // so the model has full context when generating the recipe.
            let stream = session.streamResponse(
                to: "Now provide the full recipe details for the dish.",
                generating: RecipeDetail.self
            )

            for try await snapshot in stream {
                recipeDetail = snapshot.content
            }

        } catch {
            errorMessage = friendlyError(error)
        }

        isLoading = false
    }

    // MARK: - Helpers

    private func friendlyError(_ error: Error) -> String {
        let description = error.localizedDescription.lowercased()
        if description.contains("guardrail") {
            return "That request isn't something I can help with. Try asking about a recipe!"
        } else if description.contains("context") || description.contains("window") {
            return "The conversation has gotten too long. Please start a new one."
        } else if description.contains("language") {
            return "Please ask your question in a supported language."
        }
        return error.localizedDescription
    }

    private func unavailabilityMessage(
        for reason: SystemLanguageModel.Availability.UnavailableReason
    ) -> String {
        switch reason {
        case .deviceNotEligible:
            return "Apple Intelligence requires iPhone 15 Pro or later, or an M-series iPad or Mac."
        case .appleIntelligenceNotEnabled:
            return "Apple Intelligence is not enabled. Go to Settings → Apple Intelligence & Siri to turn it on."
        default:
            return "Apple Intelligence is not available right now. Please check your device settings."
        }
    }
}
