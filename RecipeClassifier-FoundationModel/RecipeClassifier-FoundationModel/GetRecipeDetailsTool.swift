import FoundationModels

// MARK: - GetRecipeDetailsTool
//
// A Tool is a Swift function the model can call when it needs
// information or wants to take an action.
//
// The Tool protocol requires:
//   - name: short identifier, no spaces
//   - description: one clear sentence — this is what the model reads
//     to decide when to call it. Keep it short and specific.
//   - Arguments: a @Generable struct — guarantees the model can never
//     pass invalid or missing arguments
//   - call(...) -> String: String satisfies PromptRepresentable,
//     which is what the Output associated type requires

struct GetRecipeDetailsTool: Tool {

    let name = "getRecipeDetails"
    let description = "Get detailed ingredients and step-by-step cooking instructions for a specific dish."

    @Generable
    struct Arguments {
        @Guide(description: "The specific dish name to get a recipe for")
        var dishName: String

        @Guide(description: "The cuisine category, e.g. asian, italian, mexican")
        var category: String
    }

    func call(arguments: Arguments) async throws -> String {
        // In a real app this could call a recipe API, query a database,
        // or look up user dietary preferences.
        // Here we return a descriptive string so the model generates
        // the full RecipeDetail from its own knowledge.
        return """
            Dish: \(arguments.dishName)
            Category: \(arguments.category)
            Please generate a full recipe with a warm description, \
            cooking time in minutes, ingredients with quantities, \
            and clear step-by-step cooking instructions.
            """
    }
}