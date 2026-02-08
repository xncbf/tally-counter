import SwiftUI
import GoogleMobileAds

@main
struct TallyApp: App {
    init() {
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
