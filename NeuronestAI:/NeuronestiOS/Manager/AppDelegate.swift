import UIKit
import GoogleMobileAds

final class AppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {

    MobileAds.shared.start()   // ✅ completionHandler 없음
    return true
  }
}
