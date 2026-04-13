import FoundationModels

// MARK: - RecipeClassification
//
// The first thing the model generates — a quick cuisine classification.
// This appears instantly (like the CoreML demo) while the full recipe
// streams in below it.

@Generable
struct RecipeClassification {
    @Guide(description: "The cuisine category: italian, mexican, asian, american, mediterranean, breakfast, dessert, or other")
    var category: String
}

// MARK: - RecipeDetail
//
// The full recipe the model generates after calling GetRecipeDetailsTool.
//
// Property order matters — the model generates properties top to bottom.
// dishName appears first so the user sees it immediately.
// steps appears last because it is the longest content.

@Generable
struct RecipeDetail {

    @Guide(description: "The full name of the dish")
    var dishName: String

    @Guide(description: "A warm, one-paragraph description of the dish and its origins")
    var description: String

    @Guide(description: "Estimated total cooking time in minutes as a whole number")
    var cookingTimeMinutes: Int

    @Guide(description: "List of ingredients with quantities, e.g. '200g spaghetti', '2 cloves garlic'")
    var ingredients: [String]

    @Guide(description: "Step-by-step cooking instructions. Each step should be a clear, complete sentence.")
    var steps: [String]
}
