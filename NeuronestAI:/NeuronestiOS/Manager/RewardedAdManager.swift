import Combine
import Foundation
import Foundation
import GoogleMobileAds
import UIKit

@MainActor
final class RewardedAdManager: NSObject, ObservableObject {
    @Published var isLoading = false
    @Published var lastError: String?

    private var rewardedAd: RewardedAd?

    // TODO: 너의 Rewarded 광고 유닛 ID
    private let adUnitID: String = "ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx"

    // ✅ 1번 “끝까지 시청” = 25초 적립 (4번이면 100초)
    private let creditPerComplete: Int = 25

    func load() {
        guard !isLoading else { return }
        isLoading = true
        lastError = nil

        // ✅ 최신 API: with: request:
        RewardedAd.load(with: adUnitID, request: Request()) { [weak self] ad, error in
            Task { @MainActor in
                self?.isLoading = false
                if let error = error {
                    self?.rewardedAd = nil
                    self?.lastError = error.localizedDescription
                } else {
                    self?.rewardedAd = ad
                }
            }
        }
    }

    func show(from rootVC: UIViewController, premium: PremiumStore) {
        guard let ad = rewardedAd else {
            lastError = "Ad not ready yet. Loading..."
            load()
            return
        }
        lastError = nil

        // ✅ 최신 API: present(from:)
        ad.present(from: rootVC) { [weak self] in
            premium.addWatchCredit(seconds: self?.creditPerComplete ?? 25)

            // 다음 광고 준비
            self?.rewardedAd = nil
            self?.load()
        }
    }
}
