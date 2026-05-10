import XCTest
import EvalKit
import FoundationModels
@testable import RecipeClassifierDemo_Evaluation

final class EvaluationQualityGateTests: XCTestCase {

    // MARK: - Test Data

    /// Loads test cases from test_data.csv, located one directory above this file.
    private func loadCSVCases() throws -> [RecipeClassificationCase] {
        let csvURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()          // RecipeClassifierEvaluationTests/
            .deletingLastPathComponent()          // RecipeClassifier-Evaluation/
            .appendingPathComponent("test_data.csv")

        let raw = try String(contentsOf: csvURL, encoding: .utf8)
        var cases: [RecipeClassificationCase] = []

        // Skip header row; split each line at the last comma so texts that
        // contain commas are handled correctly.
        for (index, line) in raw.components(separatedBy: .newlines).dropFirst().enumerated() {
            guard !line.isEmpty,
                  let commaRange = line.range(of: ",", options: .backwards) else { continue }
            let text  = String(line[line.startIndex ..< commaRange.lowerBound])
            let label = String(line[commaRange.upperBound...])
            let example = LabeledExample(id: index, text: text, label: label)
            cases.append(RecipeClassificationCase(example: example))
        }

        return cases
    }

    // MARK: - CoreML

    func testCoreMLModelMeetsBaseline() async throws {
        let cases  = try loadCSVCases()
        let runner = RecipeClassificationRunner()

        var results: [EvaluationResult] = []
        for testCase in cases {
            results.append(try await runner.run(testCase))
        }

        let reporter = StandardClassificationReporter(minimumAccuracy: 0.85, labels: FoodCategory.allRawValues)
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

        let cases  = try loadCSVCases()
        let runner = RecipeLLMRunner()

        var results: [EvaluationResult] = []
        for testCase in cases {
            results.append(try await runner.run(testCase))
        }

        let reporter = StandardClassificationReporter(minimumAccuracy: 0.80, labels: FoodCategory.allRawValues)
        let report   = reporter.report(from: results, featureName: "RecipeClassifier (Foundation Model)")
        XCTAssert(report.passedBaseline, "Foundation Model accuracy fell below 80 % baseline: \(report.baselineDescription ?? "")")
    }
}
