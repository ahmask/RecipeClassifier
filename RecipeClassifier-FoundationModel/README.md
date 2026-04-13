# RecipeClassifier-FoundationModel

A companion project of the *Experimenting with Apple ML* series.

This app takes the `RecipeClassifierDemo` CoreML project and rebuilds it using Apple's **Foundation Models framework** (iOS 26).

It keeps the familiar **cuisine classification badge** from the CoreML demo (🍜 Asian, 🍝 Italian, etc.) — but now the LLM classifies it. Then it streams a full recipe — dish name, description, ingredients, and step-by-step instructions — all in one single call, entirely on device.

---

## Requirements

- **Xcode 26** or later
- **iOS 26** deployment target
- **Apple Intelligence-enabled device** — iPhone 15 Pro or later, M-series iPad or Mac
- No third-party packages — only `FoundationModels` (system framework)

> The simulator does not support Foundation Models. A real device with Apple Intelligence enabled is required.

---

## How to run

1. Clone the repo
2. Open `RecipeClassifier-FoundationModel.xcodeproj` in Xcode 26
3. Select your Apple Intelligence-enabled device as the run destination
4. Hit **Run**

---

## What happens when you type a query

1. `session.streamResponse(generating: RecipeResponse.self)` starts streaming
2. `category` is the first property in `RecipeResponse` → badge appears almost instantly
3. `dishName`, `description`, `cookingTimeMinutes`, `ingredients`, and `steps` fill in progressively
4. Follow-up questions (*"make it vegetarian"*) work because the session remembers the full conversation

---

## Project structure

```
RecipeClassifier-FoundationModel/
├── RecipeClassifierFoundationModelApp.swift   # App entry point
├── ContentView.swift                          # UI — badge, streaming card, unavailable state
├── RecipeViewModel.swift                      # Session and streaming logic
├── RecipeModels.swift                         # RecipeResponse @Generable struct
└── GetRecipeDetailsTool.swift                 # Reference only — see note inside
```

---

## Key features demonstrated

| Feature | Where |
|---|---|
| `@Generable` + `@Guide` | `RecipeModels.swift` |
| Single `streamResponse` call | `RecipeViewModel` — `ask()` |
| Badge from first streamed property | `ContentView` — `ClassificationBadgeView` |
| Stateful multi-turn session | `RecipeViewModel` — single session persists |
| Availability checking | `RecipeViewModel` — `setupSession()` |
| Progressive UI with `PartiallyGenerated` | `ContentView` — `RecipeCardView` |

---

## Why no tool calling?

Tool calling is explained in the article and `GetRecipeDetailsTool.swift` has a full note. The short version: splitting the request into two separate turns caused the model's guardrails to fire on the vague second prompt. A single `streamResponse` with a combined `RecipeResponse` struct is simpler, faster, and guardrail-safe — and still demonstrates every other key feature of the framework.

---

## Compared to the CoreML version

| | CoreML (`RecipeClassifierDemo`) | Foundation Models |
|---|---|---|
| Cuisine badge | ✅ `nlModel.predictedLabel()` | ✅ First property in `RecipeResponse` streams instantly |
| Full recipe | ❌ | ✅ Streams name, description, ingredients, steps |
| Training required | Yes — 72 labeled examples | No |
| Follow-up questions | No | Yes — session remembers context |
| Streaming | No | Yes |
| Model file in app | ~100KB `.mlmodel` | 0 bytes — model is in the OS |
| Works on all devices | Yes (iOS 18+) | Apple Intelligence devices only |

---

*Based on WWDC 2025: "Meet the Foundation Models framework."*
*Full article: [RecipeClassifier-FoundationModel](https://github.com/ahmask/RecipeClassifier-FoundationModel)*
