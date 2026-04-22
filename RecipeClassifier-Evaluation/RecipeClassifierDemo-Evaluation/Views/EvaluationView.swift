import SwiftUI
import EvalKit

/// Root view — shows two evaluation paths: CoreML and Foundation Models.
///
/// CoreML path: always available (iOS 18+).
/// Foundation Models path: requires iOS 26 + Apple Intelligence.
struct EvaluationView: View {
    @StateObject private var vm = EvaluatorViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // ── Path A: CoreML ─────────────────────────────────
                    PathSection(
                        title:       "Path A — CoreML",
                        subtitle:    "RecipeClassifier.mlmodel · NLModel · < 1 ms/query",
                        icon:        "cpu",
                        isRunning:   vm.coreMLIsRunning,
                        progress:    vm.coreMLProgress,
                        errorMsg:    vm.coreMLError,
                        report:      vm.coreMLReport,
                        buttonLabel: "Run CoreML Evaluation"
                    ) {
                        Task { await vm.runCoreML() }
                    }

                    Divider()

                    // ── Path B: Foundation Models ──────────────────────
                    PathSection(
                        title:       "Path B — Foundation Models",
                        subtitle:    "LanguageModelSession · @Generable output · ~800 ms/query",
                        icon:        "brain",
                        isRunning:   vm.llmIsRunning,
                        progress:    vm.llmProgress,
                        errorMsg:    vm.llmError,
                        report:      vm.llmReport,
                        buttonLabel: "Run Foundation Model Evaluation",
                        requiresiOS26: true
                    ) {
                        Task { await vm.runLLM() }
                    }
                }
                .padding()
            }
            .navigationTitle("Recipe Classifier — Evaluation")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Per-path section

private struct PathSection: View {
    let title: String
    let subtitle: String
    let icon: String
    let isRunning: Bool
    let progress: Double
    let errorMsg: String?
    let report: EvaluationReport?
    let buttonLabel: String
    var requiresiOS26: Bool = false
    let onRun: () -> Void

    var body: some View {
        VStack(spacing: 16) {

            // Header
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)
                Spacer()
                if requiresiOS26 {
                    Text("iOS 26+")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.purple.gradient, in: Capsule())
                }
            }
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Error
            if let msg = errorMsg {
                ErrorBanner(message: msg)
            }

            // Progress while running
            if isRunning {
                ProgressSection(progress: progress)
            }

            // Results once complete
            if let r = report {
                SummarySection(report: r)
                LatencySection(metrics: r.metrics)
                ClassBreakdownSection(results: r.results)
            }

            // Run button
            Button(action: onRun) {
                Label(
                    isRunning ? "Running…" : buttonLabel,
                    systemImage: isRunning ? "hourglass" : "play.fill"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRunning)
        }
    }
}

