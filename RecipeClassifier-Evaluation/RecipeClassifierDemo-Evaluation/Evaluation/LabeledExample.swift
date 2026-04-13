import Foundation

/// A single labeled example loaded from testset.json.
/// Each row contains the input text and the ground-truth category label.
struct LabeledExample: Decodable, Sendable {
    let id: Int
    let text: String
    let label: String
}

/// Loads the labeled test set bundled with the app target.
func loadTestSet() throws -> [LabeledExample] {
    guard let url = Bundle.main.url(forResource: "testset", withExtension: "json") else {
        throw URLError(.fileDoesNotExist)
    }
    let data = try Data(contentsOf: url)
    return try JSONDecoder().decode([LabeledExample].self, from: data)
}
