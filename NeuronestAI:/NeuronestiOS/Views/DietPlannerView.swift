import SwiftUI

struct DietPlannerView: View {
    @StateObject private var cache = DietCacheStore()
    @StateObject private var vm: DietPlannerViewModel

    init() {
        let cache = DietCacheStore()
        _cache = StateObject(wrappedValue: cache)
        _vm = StateObject(wrappedValue: DietPlannerViewModel(cache: cache))
    }

    @State private var selectedMeal: DietPlannerViewModel.Meal? = nil
    @State private var showSheet = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 14) {
                Text("🥗 Diet Planner")
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundStyle(.white)

                Text("Tap a meal to generate a brain-health friendly menu.\n(No medical diagnosis)")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.65))

                mealButton("🍳 Breakfast", meal: .breakfast)
                mealButton("🥪 Lunch", meal: .lunch)
                mealButton("🍲 Dinner", meal: .dinner)

                if let err = vm.errorText {
                    Text(err)
                        .foregroundStyle(.red)
                        .font(.footnote)
                        .padding(.top, 12)
                }

                Spacer()
            }
            .padding(.top, 40)
            .padding(.horizontal, 18)
        }
        .sheet(isPresented: $showSheet) {
            DietResultSheet(
                title: selectedMeal?.rawValue ?? "Diet",
                isLoading: vm.isLoading,
                text: vm.resultText,
                error: vm.errorText
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private func mealButton(_ title: String, meal: DietPlannerViewModel.Meal) -> some View {
        Button {
            selectedMeal = meal
            showSheet = true
            vm.generate(meal: meal)
        } label: {
            HStack {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
                Image(systemName: "sparkles")
                    .foregroundStyle(.white.opacity(0.8))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.10))
            )
        }
        .buttonStyle(.plain)
    }
}

private struct DietResultSheet: View {
    let title: String
    let isLoading: Bool
    let text: String
    let error: String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                if isLoading {
                    HStack(spacing: 10) {
                        ProgressView().tint(.white)
                        Text("Generating…")
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(.top, 8)
                } else if let error {
                    Text(error)
                        .foregroundStyle(.red)
                        .padding(.top, 8)
                } else {
                    ScrollView {
                        Text(text.isEmpty ? "No result." : text)
                            .foregroundStyle(.white.opacity(0.85))
                            .textSelection(.enabled)
                            .padding(.top, 6)
                    }
                }

                Spacer()
            }
            .padding(18)
        }
    }
}
