import Observation
import SwiftUI
import FoundationModels

@Observable
@MainActor
class RecipeViewModel {

    // Step 1 result — classification badge
    var classification: RecipeClassification?

    // Step 2 result — streaming recipe card
    var recipeDetail: RecipeDetail.PartiallyGenerated?

    var isAvailable: Bool = false
    var isLoading: Bool = false
    var errorMessage: String?

    // Expose session.isResponding to the UI so we can disable
    // the Ask button while the model is generating
    var isResponding: Bool {
        session?.isResponding ?? false
    }

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
                    always use the getRecipeDetails tool to fetch the recipe.
                    Keep your responses focused on cooking and food.
                    Be warm, encouraging, and enthusiastic about cooking.
                    If the user asks a follow-up like "make it vegetarian" or
                    "make it spicier", adapt the previous recipe accordingly
                    and call getRecipeDetails again with the updated dish name.
                    """
            )
            // prewarm() loads the model in the background immediately,
            // so the first response feels fast instead of loading cold.
            // Think of it as preheating the oven before you cook.
            Task { try? await session?.prewarm() }

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
            // Step 1 — classify instantly
            // respond() waits for the full result, which is tiny and fast.
            // The badge appears as soon as this returns.
            let classifyResponse = try await session.respond(
                to: trimmed,
                generating: RecipeClassification.self
            )
            classification = classifyResponse.content

            // Step 2 — stream the full recipe
            // The prompt includes the actual dish name from Step 1 —
            // always be specific, never vague. Vague prompts risk
            // triggering the model's safety guardrails.
            // The session remembers Step 1 in its transcript,
            // giving the model full context for this step.
            let dishName = classifyResponse.content.dishName ?? trimmed
            let stream = session.streamResponse(
                to: "Generate a full recipe for \(dishName).",
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
        if description.contains("guardrail") || description.contains("unsafe") {
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
