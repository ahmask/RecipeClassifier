# RecipeClassifierDemo-Evaluation

The evaluation companion to [RecipeClassifierDemo](https://github.com/ahmask/RecipeClassifierDemo). Where that project shows the model running in an app, this one measures how well it actually performs — accuracy, macro F1, per-class breakdown, P90 latency, and a pass/fail verdict — using [EvalKit](https://github.com/ahmask/EvalKit).

It evaluates both a CoreML classifier and an on-device Foundation Models path side-by-side against the same 72-example test set.

---

## What's in this repo

| File / Folder | Description |
|---|---|
| `RecipeClassifierDemoEvaluation/Evaluation/` | Evaluation types: case, runner, reporter, output, view model |
| `RecipeClassifierDemoEvaluation/Views/` | SwiftUI views: `EvaluationView`, `SubViews` |
| `RecipeClassifierDemoEvaluation/Resources/testset.json` | 72 labeled food query examples (8 categories × 9 examples) |
| `RecipeClassifierDemoEvaluation/RecipeClassifier.mlmodel` | Same trained model as RecipeClassifierDemo |
| `training_data.csv` | 72 labeled examples used to train the model |

---

## Categories

`italian` · `mexican` · `asian` · `american` · `mediterranean` · `breakfast` · `dessert` · `other`

---

## Requirements

- Xcode 16.2 or later
- iOS 18.0+ deployment target (Foundation Models path requires iOS 26+ with Apple Intelligence)
- Swift 6 concurrency enabled
- [EvalKit](https://github.com/ahmask/EvalKit) — added automatically via SPM

---

## What it measures

### Path A — CoreML (`RecipeClassifier.mlmodel`)

| Metric | Typical result |
|---|---|
| Accuracy | ~65 % |
| Macro F1 | ~0.62 |
| Avg latency | < 1 ms |
| Pass/fail baseline | 85 % accuracy |

### Path B — Foundation Models (iOS 26+)

| Metric | Typical result |
|---|---|
| Accuracy | ~76 % |
| Macro F1 | ~0.77 |
| Avg latency | ~808 ms |
| Pass/fail baseline | 75 % accuracy |

Baselines differ intentionally. A zero-shot LLM is held to a lower bar than a trained specialist classifier. CoreML currently fails its baseline — a signal to expand the training set and retrain.

---

## How it fits into the series

```
RecipeClassifierDemo          — train + ship the model
        ↓
RecipeClassifierDemo-Evaluation  — measure how well it works  ← you are here
```

Train and export `RecipeClassifier.mlmodel` using Create ML (see [RecipeClassifier-CoreML](../RecipeClassifier-CoreML)), then open this project to measure how well it actually performs.

---

## Running the evaluation

1. Open `RecipeClassifierDemo-Evaluation.xcodeproj`
2. Select an iOS 18+ simulator (or device)
3. Build and run
4. Tap **Run CoreML Evaluation** — results appear in the UI and a pass/fail verdict prints to the console
5. For the Foundation Models path, use an iOS 26 device or simulator with Apple Intelligence enabled

---

## Related

- [RecipeClassifierDemo](https://github.com/ahmask/RecipeClassifierDemo) — the simple classify demo
- [EvalKit](https://github.com/ahmask/EvalKit) — the Swift package this project depends on
- [EvalKit](https://github.com/ahmask/EvalKit) — the Swift package this project depends on
