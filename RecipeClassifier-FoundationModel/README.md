# RecipeClassifier-FoundationModel

This app takes the recipe classifier from [RecipeClassifier-CoreML](../RecipeClassifier-CoreML) and rebuilds it using Apple's **Foundation Models framework** (iOS 26). Instead of a trained text classifier, it uses the on-device language model to classify the cuisine, then streams a full recipe word by word.

---

## Requirements

- **Xcode 26 beta** or later
- **iOS 26** deployment target
- **Apple Intelligence-enabled device** — iPhone 15 Pro or later, M-series iPad or Mac
- No third-party packages — only `FoundationModels` (system framework)

> The simulator does not support Foundation Models. A real device with Apple Intelligence enabled is required.

---

## How to run

1. Clone the repo
2. Open `RecipeClassifier-FoundationModel.xcodeproj` in Xcode 26
3. Select your Apple Intelligence-enabled device
4. Hit **Run**

---

## What happens when you type a query

| Step | What happens |
|---|---|
| Immediately | Content tagging adapter extracts dietary tags + ingredients from your query |
| Step 1 | `respond(generating: RecipeClassification.self)` — classifies cuisine, identifies dish → badge appears |
| Step 2 | `streamResponse(generating: RecipeDetail.self)` — model calls `GetRecipeDetailsTool`, then streams the full recipe progressively |
| Follow-up | *"make it vegetarian"* — session transcript remembers the full conversation |

---

## Project structure

```
RecipeClassifier-FoundationModel/
├── RecipeClassifierFoundationModelApp.swift   # App entry point
├── ContentView.swift                          # UI — tags, badge, streaming card, unavailable state
├── RecipeViewModel.swift                      # Main session, prewarm, isResponding, two-step flow
├── RecipeTaggingSession.swift                 # Content tagging adapter — runs independently
├── RecipeModels.swift                         # @Generable structs: RecipeClassification, RecipeDetail, RecipeTagResult
└── GetRecipeDetailsTool.swift                 # Tool the model calls for recipe details
```

---

## Session topics covered

| Topic | Where |
|---|---|
| `@Generable` + `@Guide` | `RecipeModels.swift` |
| `respond(generating:)` | `RecipeViewModel` — Step 1 |
| `streamResponse` + `PartiallyGenerated` | `RecipeViewModel` — Step 2, `ContentView` |
| Tool calling | `GetRecipeDetailsTool.swift` |
| Content tagging adapter | `RecipeTaggingSession.swift` |
| Instructions vs. Prompts | `RecipeViewModel.setupSession()` |
| Stateful session / transcript | Single session in `RecipeViewModel` |
| `prewarm()` | `RecipeViewModel.setupSession()` |
| `isResponding` | `RecipeViewModel.isResponding`, button in `ContentView` |
| Availability + error handling | `RecipeViewModel` |

---

## Compared to the CoreML version

| | CoreML (`RecipeClassifierDemo`) | Foundation Models |
|---|---|---|
| Query tagging | ❌ | ✅ Content tagging adapter |
| Cuisine badge | ✅ `nlModel.predictedLabel()` | ✅ `respond(generating: RecipeClassification.self)` |
| Full recipe | ❌ | ✅ Streams progressively |
| Tool calling | ❌ | ✅ `GetRecipeDetailsTool` |
| Follow-up questions | ❌ | ✅ Session transcript |
| Training required | Yes — 72 labeled examples | No |
| Model file in app | ~100KB `.mlmodel` | 0 bytes — in the OS |
| Works on all devices | Yes (iOS 18+) | Apple Intelligence devices only |

---

*Based on WWDC 2025: "Meet the Foundation Models framework."*
*Full step-by-step tutorial: [RecipeClassifier-FoundationModel](https://github.com/ahmask/RecipeClassifier-FoundationModel)*
