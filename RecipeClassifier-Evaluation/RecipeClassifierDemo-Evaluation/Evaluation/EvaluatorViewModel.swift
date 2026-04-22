import Combine
import SwiftUI
import FoundationModels
import EvalKit

/// Orchestrates the evaluation pipeline for both model paths.
///
/// - `runCoreML()` — always available (iOS 18+). Uses RecipeClassifier.mlmodel
///   via NaturalLanguage.NLModel. Sub-millisecond latency.
///
/// - `runLLM()` — requires iOS 26+ with Apple Intelligence available.
///   Uses LanguageModelSession with @Generable structured output.
///   Higher accuracy, ~800 ms average latency.
@MainActor
final class EvaluatorViewModel: ObservableObject {

    // MARK: - CoreML path

    @Published var coreMLReport: EvaluationReport?
    @Published var coreMLIsRunning = false
    @Published var coreMLProgress: Double = 0
    @Published var coreMLError: String?

    // MARK: - Foundation Models path

    @Published var llmReport: EvaluationReport?
    @Published var llmIsRunning = false
    @Published var llmProgress: Double = 0
    @Published var llmError: String?

    // MARK: - CoreML evaluation

    func runCoreML() async {
        coreMLIsRunning = true
        coreMLProgress  = 0
        coreMLReport    = nil
        coreMLError     = nil

        let examples: [LabeledExample]
        do {
            examples = try loadTestSet()
        } catch {
            coreMLError     = "Could not load testset.json: \(error.localizedDescription)"
            coreMLIsRunning = false
            return
        }

        let cases  = examples.map { RecipeClassificationCase(example: $0) }
        let runner = RecipeClassificationRunner()

        var results = [EvaluationResult]()
        results.reserveCapacity(cases.count)

        for (index, testCase) in cases.enumerated() {
            let result: EvaluationResult
            do {
                result = try await runner.run(testCase)
            } catch {
                result = EvaluationResult(
                    id: testCase.id, isCorrect: false, latencyMs: 0,
                    error: error.localizedDescription
                )
            }
            results.append(result)
            coreMLProgress = Double(index + 1) / Double(cases.count)
        }

        // CoreML: trained classifier, held to a high 85 % accuracy bar.
        let reporter    = RecipeClassificationReporter(baseline: 0.85)
        let finalReport = reporter.report(from: results, featureName: "RecipeClassifier (CoreML)")
        coreMLReport    = finalReport
        coreMLIsRunning = false

        printSummary(finalReport)
    }

    // MARK: - Foundation Models evaluation

    func runLLM() async {
        guard #available(iOS 26.0, *) else {
            llmError = "Foundation Models requires iOS 26 or later."
            return
        }
        // Verify Apple Intelligence is available on this device.
        guard case .available = SystemLanguageModel.default.availability else {
            llmError = "Apple Intelligence is not available on this device. " +
                       "Enable it in Settings › Apple Intelligence & Siri and " +
                       "wait for the model to finish downloading."
            return
        }
        await runLLMInternal()
    }

    @available(iOS 26.0, *)
    private func runLLMInternal() async {
        llmIsRunning = true
        llmProgress  = 0
        llmReport    = nil
        llmError     = nil

        let examples: [LabeledExample]
        do {
            examples = try loadTestSet()
        } catch {
            llmError     = "Could not load testset.json: \(error.localizedDescription)"
            llmIsRunning = false
            return
        }

        let cases  = examples.map { RecipeClassificationCase(example: $0) }
        let runner = RecipeLLMRunner()

        var results = [EvaluationResult]()
        results.reserveCapacity(cases.count)

        for (index, testCase) in cases.enumerated() {
            let result: EvaluationResult
            do {
                result = try await runner.run(testCase)
            } catch {
                result = EvaluationResult(
                    id: testCase.id, isCorrect: false, latencyMs: 0,
                    error: error.localizedDescription
                )
            }
            results.append(result)
            llmProgress = Double(index + 1) / Double(cases.count)
        }

        // Foundation Models: zero-shot generalist. 75 % is a realistic bar for a
        // custom taxonomy that mixes cuisine types with meal-type categories.
        // A trained CoreML model will always outperform zero-shot LLM classification
        // on narrow taxonomies like this one.
        let reporter    = RecipeClassificationReporter(baseline: 0.75)
        let finalReport = reporter.report(from: results, featureName: "RecipeClassifier (Foundation Model)")
        llmReport    = finalReport
        llmIsRunning = false

        printSummary(finalReport)
    }

    // MARK: - Console output

    private func printSummary(_ r: EvaluationReport) {
        let m = r.metrics
        let hallInfo: String = {
            guard let count = m.hallucinationCount,
                  let rate  = m.hallucinationRate else { return "" }
            return "\nHallucinations: \(count) (\(String(format: "%.1f %%", rate * 100)))"
        }()
        print("────────────────────────────────────────────")
        print("Feature:        \(r.featureName)")
        print("Total cases:    \(m.totalCases)")
        print("Errors:         \(m.errorCount)\(hallInfo)")
        print("────────────────────────────────────────────")
        print("Accuracy:       \(String(format: "%.1f %%", (m.accuracy ?? 0) * 100))")
        print("Macro F1:       \(String(format: "%.4f",    m.macroF1 ?? 0))")
        print("Macro Precision:\(String(format: "%.4f",    m.macroPrecision ?? 0))")
        print("Macro Recall:   \(String(format: "%.4f",    m.macroRecall ?? 0))")
        print("Weighted F1:    \(String(format: "%.4f",    m.weightedF1 ?? 0))")
        print("────────────────────────────────────────────")
        print("Avg latency:    \(String(format: "%.2f ms", m.latencyMsMean))")
        print("P90 latency:    \(String(format: "%.2f ms", m.latencyMsP90))")
        print("────────────────────────────────────────────")
        print("Baseline:       \(r.passedBaseline ? "✓ PASS" : "✗ FAIL") — \(r.baselineDescription ?? "")")
        print("────────────────────────────────────────────")
    }
}
