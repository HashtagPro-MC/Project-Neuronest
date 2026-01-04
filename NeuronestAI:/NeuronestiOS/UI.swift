import UIKit

extension UIApplication {
    func topMostViewController() -> UIViewController? {
        guard
            let scene = connectedScenes.first as? UIWindowScene,
            let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else { return nil }

        var top = root
        while let presented = top.presentedViewController { top = presented }
        return top
    }
}
