//
//  AdBannerView.swift
//  NeuronestiOS
//
//  Created by HashtagPro on 12/31/25.
//


import SwiftUI
import GoogleMobileAds

struct AdBannerView: UIViewRepresentable {
    let adUnitID: String

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = adUnitID
        banner.rootViewController = context.coordinator.rootVC
        banner.delegate = context.coordinator
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        // no-op
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, BannerViewDelegate {
        let rootVC = UIViewController()

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            // Optional: print("✅ Ad received")
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            // Optional: print("❌ Ad failed: \(error.localizedDescription)")
        }
    }
}
