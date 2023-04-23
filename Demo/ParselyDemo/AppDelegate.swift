import UIKit
import ParselyAnalytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // This is unused but necessary in a Storyboard without UISceneDelegate setup.
    // Without it, the app will show a black screen and log:
    //
    // > The app delegate must implement the window property if it wants to use a main storyboard file.
    var window: UIWindow?

    var parsely: Parsely!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.parsely = Parsely.sharedInstance
        self.parsely.configure(siteId: "parsely-configured-default.com")
        
        return true
    }
}
