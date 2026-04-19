import FoundationModels

// MARK: - GetRecipeDetailsTool
//
// A Tool is a Swift function the model can call when it needs information
// or wants to take an action. The @Generable Arguments struct guarantees
// the model can never pass invalid or missing arguments.

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
        // In a real app this could call a recipe API or query a database.
        // Returning a descriptive string lets the model generate the full
        // RecipeDetail from its own knowledge.
        return """
            Dish: \(arguments.dishName)
            Category: \(arguments.category)
            Please generate a full recipe with a warm description, \
            cooking time in minutes, ingredients with quantities, \
            and clear step-by-step cooking instructions.
            """
    }
}
