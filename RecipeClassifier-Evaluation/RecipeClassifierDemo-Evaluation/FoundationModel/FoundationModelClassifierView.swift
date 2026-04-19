import SwiftUI

struct FoundationModelClassifierView: View {

    @State private var viewModel = RecipeViewModel()
    @State private var taggingSession = RecipeTaggingSession()
    @State private var queryText = ""
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // ── Input ──────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ask about any recipe")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TextField(
                            "e.g. Tiramisu",
                            text: $queryText,
                            axis: .vertical
                        )
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                        .focused($inputFocused)
                        .onSubmit { submitQuery() }
                    }

                    // ── Action ─────────────────────────────────────────
                    Button {
                        submitQuery()
                        inputFocused = false
                    } label: {
                        Label(
                            viewModel.isLoading ? "Thinking..." : "Ask",
                            systemImage: viewModel.isLoading ? "ellipsis" : "sparkle"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(
                        queryText.trimmingCharacters(in: .whitespaces).isEmpty ||
                        viewModel.isLoading ||
                        viewModel.isResponding ||
                        !viewModel.isAvailable
                    )

                    // ── Unavailability notice ──────────────────────────
                    if !viewModel.isAvailable, let message = viewModel.errorMessage {
                        FMUnavailableView(message: message)
                    }

                    // ── Error ──────────────────────────────────────────
                    if viewModel.isAvailable, let error = viewModel.errorMessage {
                        Text(error)
                            .font(.callout)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }

                    // ── Content tagging result ─────────────────────────
                    if let tags = taggingSession.tags {
                        FMTagsView(tags: tags)
                            .transition(.scale(scale: 0.85).combined(with: .opacity))
                    }

                    // ── Classification badge ───────────────────────────
                    if let classification = viewModel.classification {
                        FMClassificationBadgeView(category: classification.category)
                            .transition(.scale(scale: 0.85).combined(with: .opacity))
                    }

                    // ── Streaming recipe card ──────────────────────────
                    if let recipe = viewModel.recipeDetail {
                        FMRecipeCardView(recipe: recipe)
                            .transition(.scale(scale: 0.92).combined(with: .opacity))
                    }

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .animation(.spring(duration: 0.4), value: viewModel.classification?.category)
            .animation(.spring(duration: 0.4), value: viewModel.recipeDetail?.dishName)
            .animation(.spring(duration: 0.3), value: taggingSession.tags?.dietaryTags.count)
            .navigationTitle("Foundation Model")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func submitQuery() {
        let trimmed = queryText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        Task { await taggingSession.extractTags(from: trimmed) }
        Task { await viewModel.ask(query: trimmed) }
    }
}

// MARK: - Tags View

private struct FMTagsView: View {
    let tags: RecipeTagResult

    var allTags: [String] {
        tags.dietaryTags + tags.ingredients
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Detected from your query")
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(allTags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.orange.opacity(0.15), in: Capsule())
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Classification Badge

private struct FMClassificationBadgeView: View {
    let category: String

    var body: some View {
        VStack(spacing: 8) {
            Text(emoji(for: category))
                .font(.system(size: 56))

            Text(category.capitalized)
                .font(.title3.bold())

            Text("on-device · no network")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private func emoji(for category: String) -> String {
        switch category {
        case "italian":       "🍝"
        case "mexican":       "🌮"
        case "asian":         "🍜"
        case "american":      "🍔"
        case "mediterranean": "🫒"
        case "breakfast":     "🥞"
        case "dessert":       "🍰"
        default:              "🍽️"
        }
    }
}

// MARK: - Recipe Card

private struct FMRecipeCardView: View {

    let recipe: RecipeDetail.PartiallyGenerated

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            if let name = recipe.dishName {
                Text(name)
                    .font(.title2.bold())
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            if let description = recipe.description {
                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }

            if let minutes = recipe.cookingTimeMinutes {
                Label("\(minutes) minutes", systemImage: "clock")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let ingredients = recipe.ingredients, !ingredients.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Ingredients")
                        .font(.headline)

                    ForEach(ingredients, id: \.self) { ingredient in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(.orange)
                                .frame(width: 6, height: 6)
                            Text(ingredient)
                                .font(.subheadline)
                        }
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    }
                }
            }

            if let steps = recipe.steps, !steps.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Steps")
                        .font(.headline)

                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(.orange, in: Circle())

                            Text(step)
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .animation(.spring(duration: 0.3), value: recipe.ingredients?.count)
        .animation(.spring(duration: 0.3), value: recipe.steps?.count)
    }
}

// MARK: - Unavailable View

struct FMUnavailableView: View {
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Apple Intelligence Unavailable")
                .font(.headline)
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}
