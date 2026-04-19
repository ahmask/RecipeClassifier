import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            Tab("CoreML", systemImage: "cpu") {
                CoreMLClassifierView()
            }

            Tab("Foundation Model", systemImage: "brain") {
                FoundationModelClassifierView()
            }

            Tab("Evaluate", systemImage: "chart.bar.xaxis") {
                EvaluationView()
            }
        }
    }
}
