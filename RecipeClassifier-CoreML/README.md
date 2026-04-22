# RecipeClassifierDemo

A minimal iOS app that classifies food and recipe queries on-device using a CoreML text classifier trained with Create ML.

Type a query — "how do I make carbonara", "best tacos for a crowd", "easy weekday breakfast" — tap **Classify**, and the model returns a category in under 1 ms. No network, no API key, no GPU.

---

## What's in this repo

| File / Folder | Description |
|---|---|
| `RecipeClassifierDemo/` | SwiftUI app source (2 files) |
| `RecipeClassifierDemo/RecipeClassifier.mlmodel` | Trained text classifier (8 food/recipe categories) |
| `training_data.csv` | 72 labeled examples used to train the model (9 per category) |
| `test_data.csv` | 24 held-out examples for evaluation (3 per category, not in training data) |

---

## Categories

`italian` · `mexican` · `asian` · `american` · `mediterranean` · `breakfast` · `dessert` · `other`

---

## Requirements

- Xcode 15 or later
- iOS 18.0+ deployment target
- No Swift packages — only `CoreML` and `NaturalLanguage` (both system frameworks)

---

## How it works

The model is a `NLTextClassifier` CoreML model trained with Create ML's **Text Classifier** template using Maximum Entropy. At runtime, `NLModel` wraps it and handles tokenisation automatically:

```swift
let nlModel = try NLModel(mlModel: RecipeClassifier(configuration: .init()).model)
let label = nlModel.predictedLabel(for: "How do I make tonkotsu ramen?")
// → "asian"
```

Inference runs on the Neural Engine at under 1 ms per query.

---

## Training the model yourself

1. Open Create ML (**Xcode → Open Developer Tool → Create ML**)
2. Create a new **Text Classifier** project named `RecipeClassifier`
3. Load `training_data.csv` as training data
4. Optionally load `test_data.csv` as test data for an in-tool accuracy check
5. Train with **Maximum Entropy** (fast, good for iteration) or **Transfer Learning** (higher accuracy, takes 1–2 minutes)
6. Export from the **Output** tab and drag into the Xcode project target

---

## Evaluating the model properly

`test_data.csv` gives you a quick accuracy check inside Create ML. For a full benchmark — macro F1, per-class recall, P90 latency, and a pass/fail verdict — see [RecipeClassifier-Evaluation](../RecipeClassifier-Evaluation) and [EvalKit](https://github.com/ahmask/EvalKit).
