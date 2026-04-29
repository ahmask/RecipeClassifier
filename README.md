# RecipeClassifier

A monorepo tracking three companion projects that explore on-device recipe classification on Apple platforms — from a trained CoreML model to a streaming Foundation Models app.

---

## Projects

### [`RecipeClassifier-CoreML`](./RecipeClassifier-CoreML)

A minimal iOS app that classifies food and recipe queries on-device using a CoreML text classifier trained with Create ML.

- 8 categories: `italian` · `mexican` · `asian` · `american` · `mediterranean` · `breakfast` · `dessert` · `other`
- Inference under 1 ms, no network, no API key
- Includes `training_data.csv` (192 examples) and `test_data.csv` (24 held-out examples)

### [`RecipeClassifier-Evaluation`](./RecipeClassifier-Evaluation)

Measures how well the CoreML model actually performs — accuracy, macro F1, per-class breakdown, P90 latency, and a pass/fail verdict — using [EvalKit](https://github.com/ahmask/EvalKit). Also evaluates a Foundation Models path side-by-side against the same test set.

- Requires iOS 18.0+ (Foundation Models path requires iOS 26+ with Apple Intelligence)
- Uses Swift Package Manager to pull in EvalKit automatically

### [`RecipeClassifier-FoundationModel`](./RecipeClassifier-FoundationModel)

Rebuilds the classifier using Apple's **Foundation Models framework** (iOS 26). The LLM classifies the cuisine, then streams a full recipe — dish name, description, ingredients, and step-by-step instructions — in a single on-device call.

- Requires Xcode 26, iOS 26, and an Apple Intelligence-enabled device (iPhone 15 Pro or later, M-series iPad or Mac)
- No third-party packages — only `FoundationModels` (system framework)

---

## How the projects relate

```
RecipeClassifier-CoreML          — train and ship the model
        ↓
RecipeClassifier-Evaluation      — measure accuracy, latency, and F1
        ↓
RecipeClassifier-FoundationModel — rebuild with Foundation Models, stream full recipes
```

---

## Requirements summary

| Project | Xcode | iOS | Notes |
|---|---|---|---|
| RecipeClassifier-CoreML | 15+ | 18.0+ | No Swift packages |
| RecipeClassifier-Evaluation | 16.2+ | 18.0+ | EvalKit via SPM; Foundation Models path needs iOS 26 |
| RecipeClassifier-FoundationModel | 26+ | 26+ | Real device with Apple Intelligence required |
