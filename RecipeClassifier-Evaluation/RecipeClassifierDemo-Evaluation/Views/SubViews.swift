import SwiftUI
import MetricKitML

// MARK: - Error banner

struct ErrorBanner: View {
    let message: String
    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .foregroundStyle(.white)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.red.gradient, in: RoundedRectangle(cornerRadius: 10))
            .font(.caption)
    }
}

// MARK: - Progress while running

struct ProgressSection: View {
    let progress: Double
    var body: some View {
        GroupBox("Running Evaluation") {
            VStack(alignment: .leading, spacing: 8) {
                ProgressView(value: progress)
                Text("\(Int(progress * 100)) % complete")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Top-level summary

struct SummarySection: View {
    let report: EvaluationReport
    private var m: EvaluationMetrics { report.metrics }

    var body: some View {
        GroupBox {
            VStack(spacing: 0) {
                // Verdict row
                HStack {
                    Text("Verdict")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Label(
                        report.passedBaseline ? "PASS" : "FAIL",
                        systemImage: report.passedBaseline
                            ? "checkmark.seal.fill"
                            : "xmark.seal.fill"
                    )
                    .font(.subheadline.bold())
                    .foregroundStyle(report.passedBaseline ? .green : .red)
                }
                .padding(.vertical, 6)
                Divider()

                MetricRow(label: "Accuracy",         value: pct(m.accuracy ?? 0))
                Divider()
                MetricRow(label: "Macro F1",          value: f4(m.macroF1 ?? 0))
                MetricRow(label: "Macro Precision",   value: f4(m.macroPrecision ?? 0))
                MetricRow(label: "Macro Recall",      value: f4(m.macroRecall ?? 0))
                Divider()
                MetricRow(label: "Weighted F1",       value: f4(m.weightedF1 ?? 0))
                MetricRow(label: "Weighted Precision",value: f4(m.weightedPrecision ?? 0))
                MetricRow(label: "Weighted Recall",   value: f4(m.weightedRecall ?? 0))
                Divider()
                MetricRow(label: "Total cases",       value: "\(m.totalCases)")
                MetricRow(
                    label: "Errors",
                    value: "\(m.errorCount)",
                    accent: m.errorCount > 0 ? .orange : nil
                )
                // Hallucination row — only present for the Foundation Models path
                if let rate = m.hallucinationRate, let count = m.hallucinationCount {
                    MetricRow(
                        label: "Hallucinations",
                        value: "\(count) (\(String(format: "%.1f %%", rate * 100)))",
                        accent: count > 0 ? .orange : .green
                    )
                }
            }
        } label: {
            Label("Summary — \(report.featureName)", systemImage: "checkmark.seal")
                .font(.headline)
        }
    }

    private func pct(_ v: Double) -> String { String(format: "%.1f %%", v * 100) }
    private func f4(_ v: Double)  -> String { String(format: "%.4f", v) }
}

// MARK: - Latency

struct LatencySection: View {
    let metrics: EvaluationMetrics
    var body: some View {
        GroupBox {
            VStack(spacing: 0) {
                MetricRow(
                    label: "Average latency",
                    value: String(format: "%.2f ms", metrics.latencyMsMean)
                )
                Divider()
                MetricRow(
                    label: "P90 latency",
                    value: String(format: "%.2f ms", metrics.latencyMsP90)
                )
            }
        } label: {
            Label("Latency", systemImage: "stopwatch")
                .font(.headline)
        }
    }
}

// MARK: - Per-class breakdown

struct ClassBreakdownSection: View {
    let results: [EvaluationResult]

    private struct ClassRow: Identifiable {
        let id: String
        let correct: Int
        let total: Int
        var rate: Double { Double(correct) / Double(max(total, 1)) }
    }

    private var rows: [ClassRow] {
        let groups = Dictionary(grouping: results) { $0.expectedLabel ?? "unknown" }
        return groups.map { label, cases in
            ClassRow(
                id:      label,
                correct: cases.filter(\.isCorrect).count,
                total:   cases.count
            )
        }.sorted { $0.id < $1.id }
    }

    var body: some View {
        GroupBox {
            VStack(spacing: 0) {
                ForEach(rows) { row in
                    HStack {
                        Text(row.id)
                            .font(.caption)
                        Spacer()
                        Text("\(row.correct)/\(row.total)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.0f %%", row.rate * 100))
                            .font(.caption.monospacedDigit().bold())
                            .foregroundStyle(
                                row.rate >= 0.85 ? .green :
                                row.rate >= 0.70 ? .orange : .red
                            )
                            .frame(width: 44, alignment: .trailing)
                    }
                    .padding(.vertical, 4)
                    if row.id != rows.last?.id { Divider() }
                }
            }
        } label: {
            Label("Per-class breakdown", systemImage: "list.bullet")
                .font(.headline)
        }
    }
}

// MARK: - Shared metric row

struct MetricRow: View {
    let label: String
    let value: String
    var accent: Color? = nil

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(accent ?? .primary)
        }
        .padding(.vertical, 6)
    }
}
