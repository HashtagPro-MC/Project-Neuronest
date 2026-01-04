import Foundation
import Combine

@MainActor
final class DietPlannerViewModel: ObservableObject {

    enum Meal: String, CaseIterable {
        case breakfast = "Breakfast"
        case lunch = "Lunch"
        case dinner = "Dinner"
    }

    @Published var isLoading = false
    @Published var resultText: String = ""
    @Published var errorText: String? = nil
    @Published var lastSavedAt: Date? = nil

    private var client: MistralClient? = nil
    private let cache: DietCacheStore

    init(cache: DietCacheStore = DietCacheStore()) {
        self.cache = cache

        // ✅ MistralClient init은 throws → 안전하게 Task에서 생성
        Task { @MainActor in
            do {
                // 모델은 여기서 고정 (원하면 "mistral-large-latest" 등으로 변경 가능)
                self.client = try MistralClient(model: "mistral-small-latest")
            } catch {
                self.client = nil
                self.errorText = error.localizedDescription
            }
        }
    }

    /// ✅ 버튼/탭 들어오자마자 캐시 있으면 즉시 표시
    func loadCached(meal: Meal) {
        if let cached = cache.get(meal: meal.rawValue) {
            self.resultText = cached.text
            self.lastSavedAt = cached.savedAt
            self.errorText = nil
        }
    }

    /// ✅ 새로 생성
    func generate(meal: Meal, budgetLevel: String = "budget", caloriesHint: String? = nil) {
        guard let client else {
            self.errorText = "Mistral client not ready yet. Check Info.plist (MISTRAL_API_KEY) and try again."
            return
        }

        isLoading = true
        errorText = nil

        Task { @MainActor in
            do {
                let system = """
                You are Neuronest AI diet coach.
                Target user: American (US grocery stores like Walmart/Costco/Kroger are OK).
                Do NOT provide medical diagnosis or medical claims.
                Focus on practical, affordable, brain-health-friendly meals.
                Keep output structured and easy to follow.
                Use US units (cups, tbsp, oz, lb).
                """

                var user = """
                Create a brain-health-friendly \(meal.rawValue) plan.

                Requirements:
                1) Menu name: 1 main dish + 2 sides + 1 drink option
                2) Ingredients list with approximate amounts (US units)
                3) Step-by-step cooking instructions
                4) Time estimate (prep + cook)
                5) Why it supports brain health (short, non-medical)
                6) Budget tip (how to keep it cheap in the US)
                7) “Swap options” (2 simple substitutions)

                Style:
                - concise but complete
                - no extra long essays
                - no medical claims
                Budget level: \(budgetLevel)
                """

                if let caloriesHint, !caloriesHint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    user += "\nCalories preference (optional): \(caloriesHint)"
                }

                let text = try await client.chat(system: system, user: user)

                self.resultText = text
                self.isLoading = false

                // ✅ 캐시 저장
                self.cache.save(meal: meal.rawValue, text: text)
                self.lastSavedAt = Date()

            } catch {
                self.errorText = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func deleteCache(meal: Meal) {
        cache.delete(meal: meal.rawValue)
        resultText = ""
        lastSavedAt = nil
    }

    func clearAllCache() {
        cache.clearAll()
        resultText = ""
        lastSavedAt = nil
    }
}
