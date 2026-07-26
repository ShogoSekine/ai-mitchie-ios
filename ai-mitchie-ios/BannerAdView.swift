import SwiftUI
import GoogleMobileAds
import UIKit

struct BannerAdView: UIViewControllerRepresentable {
    let adUnitID: String

    func makeUIViewController(context: Context) -> BannerAdHostingController {
        let controller = BannerAdHostingController()
        controller.adUnitID = adUnitID
        return controller
    }

    func updateUIViewController(_ uiViewController: BannerAdHostingController, context: Context) {
        uiViewController.adUnitID = adUnitID
        uiViewController.loadAdIfNeeded()
    }
}

final class BannerAdHostingController: UIViewController, BannerViewDelegate {
    var adUnitID: String = "" {
        didSet {
            loadAdIfNeeded()
        }
    }

    private var bannerView: BannerView?
    private var hasLoaded = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        loadAdIfNeeded()
    }

    func loadAdIfNeeded() {
        guard !adUnitID.isEmpty, !hasLoaded else { return }
        hasLoaded = true

        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = adUnitID
        banner.rootViewController = self
        banner.delegate = self
        banner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(banner)

        NSLayoutConstraint.activate([
            banner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            banner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        banner.load(Request())
        bannerView = banner
    }

    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        print("AdMob banner loaded")
    }

    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        print("AdMob banner failed to load: \(error.localizedDescription)")
    }
}
