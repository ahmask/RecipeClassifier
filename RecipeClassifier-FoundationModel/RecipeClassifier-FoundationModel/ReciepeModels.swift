import FoundationModels

// MARK: - RecipeClassification
//
// Step 1 — the quick classification.
// A small @Generable struct the model fills in instantly.
// This is what powers the cuisine badge.

@Generable
struct RecipeClassification {
    @Guide(description: "The cuisine category: italian, mexican, asian, american, mediterranean, breakfast, dessert, or other")
    var category: String

    @Guide(description: "The specific dish name that best matches the query")
    var dishName: String
}

// MARK: - RecipeDetail
//
// Step 2 — the full recipe, generated after GetRecipeDetailsTool runs.
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

// MARK: - RecipeTagResult
//
// Used with the content tagging adapter.
// Extracts dietary tags and key ingredients from the user's query.
// For example: "spicy chicken with no dairy" → ["spicy", "chicken", "dairy-free"]

@Generable
struct RecipeTagResult {
    @Guide(description: "Dietary or flavor tags detected in the query, e.g. vegetarian, spicy, gluten-free, dairy-free")
    var dietaryTags: [String]

    @Guide(description: "Key ingredients mentioned in the query")
    var ingredients: [String]
}