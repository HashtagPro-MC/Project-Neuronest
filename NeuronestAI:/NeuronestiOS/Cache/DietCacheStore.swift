import Foundation
import Combine

final class DietCacheStore: ObservableObject {
    struct CachedMeal: Codable {
        let meal: String          // "Breakfast" | "Lunch" | "Dinner"
        let text: String
        let savedAt: Date
    }

    private let keyPrefix = "neuronest.diet.cache."
    @Published private(set) var cache: [String: CachedMeal] = [:]

    init() {
        loadAll()
    }

    func get(meal: String) -> CachedMeal? {
        cache[meal]
    }

    func save(meal: String, text: String) {
        let item = CachedMeal(meal: meal, text: text, savedAt: Date())
        cache[meal] = item
        persist(item)
    }

    func delete(meal: String) {
        cache.removeValue(forKey: meal)
        UserDefaults.standard.removeObject(forKey: keyPrefix + meal)
    }

    func clearAll() {
        for k in cache.keys {
            UserDefaults.standard.removeObject(forKey: keyPrefix + k)
        }
        cache.removeAll()
    }

    // MARK: - Private
    private func persist(_ item: CachedMeal) {
        do {
            let data = try JSONEncoder().encode(item)
            UserDefaults.standard.set(data, forKey: keyPrefix + item.meal)
        } catch {
            // ignore
        }
    }

    private func loadAll() {
        ["Breakfast", "Lunch", "Dinner"].forEach { meal in
            if let data = UserDefaults.standard.data(forKey: keyPrefix + meal),
               let item = try? JSONDecoder().decode(CachedMeal.self, from: data) {
                cache[meal] = item
            }
        }
    }
}
