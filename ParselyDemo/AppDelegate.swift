import UIKit
import ParselyTracker

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var parsely: Parsely!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.parsely = Parsely.sharedInstance
        self.parsely.configure(siteId: "parsely-configured-default.com")
        
        return true
    }
}
