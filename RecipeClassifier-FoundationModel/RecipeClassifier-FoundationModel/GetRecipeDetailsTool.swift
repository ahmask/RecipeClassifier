import FoundationModels

// MARK: - GetRecipeDetailsTool
//
// Tool protocol signature:
//   func call(arguments: Arguments) async throws -> Output
// where Output: PromptRepresentable (String satisfies this)
// and   Arguments: ConvertibleFromGeneratedContent (@Generable satisfies this)
//
// The struct must be Sendable — make it a simple value type (struct).
// No nonisolated, no ToolOutput — just return String directly.

struct GetRecipeDetailsTool: Tool {

    let name = "getRecipeDetails"
    let description = "Get detailed ingredients and step-by-step cooking instructions for a specific dish. Call this whenever the user asks how to make something or wants a full recipe."

    @Generable
    struct Arguments {
        @Guide(description: "The specific dish name to get a recipe for")
        var dishName: String

        @Guide(description: "The cuisine category of the dish, e.g. asian, italian, mexican")
        var category: String
    }

    func call(arguments: Arguments) async throws -> String {
        // In a real app this could call a recipe API or query a database.
        // We return a descriptive string so the model can use it to
        // generate the full RecipeDetail from its own knowledge.
        return "Dish: \(arguments.dishName), Category: \(arguments.category). Please generate a full recipe including a warm description, cooking time in minutes, a list of ingredients with quantities, and clear step-by-step cooking instructions."
    }
}
