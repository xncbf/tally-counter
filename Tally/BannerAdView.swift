import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewControllerRepresentable {
    let adUnitID: String
    
    func makeUIViewController(context: Context) -> BannerAdViewController {
        let vc = BannerAdViewController()
        vc.adUnitID = adUnitID
        return vc
    }
    
    func updateUIViewController(_ uiViewController: BannerAdViewController, context: Context) {}
}

class BannerAdViewController: UIViewController, GADBannerViewDelegate {
    var adUnitID: String = ""
    private var bannerView: GADBannerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bannerView = GADBannerView(adSize: GADAdSizeBanner)
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = self
        bannerView.delegate = self
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        
        NSLayoutConstraint.activate([
            bannerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bannerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        bannerView.load(GADRequest())
    }
    
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("✅ Ad received")
    }
    
    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        print("❌ Ad failed: \(error.localizedDescription)")
    }
}
