import XCTest
import EvalKit
import FoundationModels
@testable import RecipeClassifierDemo_Evaluation

final class EvaluationQualityGateTests: XCTestCase {

    // MARK: - Test Data

    /// Loads test cases from testset.json — the same file the app bundles and uses on device.
    private func loadTestCases() throws -> [RecipeClassificationCase] {
        let jsonURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()          // RecipeClassifierEvaluationTests/
            .deletingLastPathComponent()          // RecipeClassifier-Evaluation/
            .appendingPathComponent("RecipeClassifierDemo-Evaluation/Resources/testset.json")

        let data     = try Data(contentsOf: jsonURL)
        let examples = try JSONDecoder().decode([LabeledExample].self, from: data)
        return examples.map { RecipeClassificationCase(example: $0) }
    }

    // MARK: - CoreML

    func testCoreMLModelMeetsBaseline() async throws {
        let cases  = try loadTestCases()
        let runner = RecipeClassificationRunner()

        var results: [EvaluationResult] = []
        for testCase in cases {
            results.append(try await runner.run(testCase))
        }

        let reporter = StandardClassificationReporter(labels: FoodCategory.allRawValues, minimumAccuracy: 0.85)
        let report   = reporter.report(from: results, featureName: "RecipeClassifier (CoreML)")

        let m = report.metrics
        let verdict = report.passedBaseline ? "✅ PASSED" : "❌ FAILED"

        print("")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📊 EVALKIT REPORT — \(report.featureName)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("  Total Cases     : \(m.totalCases)")
        print("  Passed Cases    : \(report.passCount)")
        print("  Error Count     : \(m.errorCount)")
        print("")
        if let accuracy = m.accuracy {
            print("  Accuracy        : \(String(format: "%.1f%%", accuracy * 100))")
        }
        if let precision = m.macroPrecision {
            print("  Precision (macro): \(String(format: "%.1f%%", precision * 100))")
        }
        if let recall = m.macroRecall {
            print("  Recall (macro)  : \(String(format: "%.1f%%", recall * 100))")
        }
        if let f1 = m.macroF1 {
            print("  F1 (macro)      : \(String(format: "%.1f%%", f1 * 100))")
        }
        print("")
        print("  Latency Mean    : \(String(format: "%.1f", m.latencyMsMean))ms")
        print("  Latency P90     : \(String(format: "%.1f", m.latencyMsP90))ms")
        if let baseline = report.baselineDescription {
            print("  Baseline        : \(baseline)")
        }
        print("")
        print("  Verdict         : \(verdict)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")

        XCTAssert(report.passedBaseline, "CoreML accuracy fell below 85 % baseline: \(report.baselineDescription ?? "")")
    }

    // MARK: - Foundation Models

    func testFoundationModelEvaluation() async throws {
        guard case .available = SystemLanguageModel.default.availability else {
            throw XCTSkip("Foundation Models not available on this machine")
        }

        let cases  = try loadTestCases()
        let runner = RecipeLLMRunner()

        var results: [EvaluationResult] = []
        for testCase in cases {
            results.append(try await runner.run(testCase))
        }

        let reporter = StandardClassificationReporter(labels: FoodCategory.allRawValues, minimumAccuracy: 0.80)
        let report   = reporter.report(from: results, featureName: "RecipeClassifier (Foundation Model)")

        let m = report.metrics
        let verdict = report.passedBaseline ? "✅ PASSED" : "❌ FAILED"

        print("")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📊 EVALKIT REPORT — \(report.featureName)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("  Total Cases     : \(m.totalCases)")
        print("  Passed Cases    : \(report.passCount)")
        print("  Error Count     : \(m.errorCount)")
        print("")
        if let accuracy = m.accuracy {
            print("  Accuracy        : \(String(format: "%.1f%%", accuracy * 100))")
        }
        if let precision = m.macroPrecision {
            print("  Precision (macro): \(String(format: "%.1f%%", precision * 100))")
        }
        if let recall = m.macroRecall {
            print("  Recall (macro)  : \(String(format: "%.1f%%", recall * 100))")
        }
        if let f1 = m.macroF1 {
            print("  F1 (macro)      : \(String(format: "%.1f%%", f1 * 100))")
        }
        print("")
        print("  Latency Mean    : \(String(format: "%.1f", m.latencyMsMean))ms")
        print("  Latency P90     : \(String(format: "%.1f", m.latencyMsP90))ms")
        if let baseline = report.baselineDescription {
            print("  Baseline        : \(baseline)")
        }
        print("")
        print("  Verdict         : \(verdict)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")

        XCTAssert(report.passedBaseline, "Foundation Model accuracy fell below 80 % baseline: \(report.baselineDescription ?? "")")
    }
}
