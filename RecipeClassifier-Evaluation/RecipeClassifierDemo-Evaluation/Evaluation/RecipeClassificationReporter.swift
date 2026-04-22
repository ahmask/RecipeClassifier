import Foundation
import EvalKit

/// Aggregates EvaluationResults into a structured EvaluationReport.
///
/// Computes accuracy, macro/weighted precision·recall·F1,
/// latency mean and P90. Pass/fail is determined by the accuracy baseline.
struct RecipeClassificationReporter: EvaluationReporter {

    /// Minimum accuracy required to pass.
    ///
    /// Use a lower value for Foundation Models (zero-shot generalist) than for
    /// a trained CoreML classifier. 0.85 is appropriate for CoreML; 0.75 is a
    /// realistic bar for a zero-shot LLM on a custom taxonomy that mixes cuisine
    /// types with meal-type categories (breakfast, dessert).
    let baseline: Double

    func report(from results: [EvaluationResult], featureName: String) -> EvaluationReport {
        let labels    = FoodCategory.allRawValues
        let prf       = PrecisionRecallF1.compute(from: results, labels: labels)
        let latencies = results.map(\.latencyMs)

        let metrics = EvaluationMetrics(
            totalCases:        results.count,
            passRate:          prf.accuracy,
            errorCount:        results.filter { $0.error != nil }.count,
            accuracy:          prf.accuracy,
            macroPrecision:    prf.macroPrecision,
            macroRecall:       prf.macroRecall,
            macroF1:           prf.macroF1,
            weightedPrecision: prf.weightedPrecision,
            weightedRecall:    prf.weightedRecall,
            weightedF1:        prf.weightedF1,
            latencyMsMean:     P90Calculator.mean(latencies),
            latencyMsP90:      P90Calculator.p90(latencies)
        )

        return EvaluationReport(
            featureName:         featureName,
            metrics:             metrics,
            results:             results,
            passedBaseline:      prf.accuracy >= baseline,
            baselineDescription: "accuracy >= \(baseline)"
        )
    }
}
