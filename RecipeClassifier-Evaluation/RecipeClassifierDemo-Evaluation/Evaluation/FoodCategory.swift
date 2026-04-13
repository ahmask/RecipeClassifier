import Foundation

/// The 8 food/recipe categories used by the classifier.
/// Raw values match the label strings in testset.json exactly.
enum FoodCategory: String, CaseIterable, Sendable {
    case italian       = "italian"
    case mexican       = "mexican"
    case asian         = "asian"
    case american      = "american"
    case mediterranean = "mediterranean"
    case breakfast     = "breakfast"
    case dessert       = "dessert"
    case other         = "other"

    /// All raw-value strings — passed to PrecisionRecallF1.compute(from:labels:).
    static var allRawValues: [String] { allCases.map(\.rawValue) }
}
