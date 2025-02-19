import SwiftUI
import Firebase
import FirebaseFirestore
import Network

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        let db = Firestore.firestore()
        let settings = db.settings
    
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        
        db.settings = settings
        
        return true
    }
}

@main
struct ToolLenderApp: App {
// register app delegate for Firebase setup
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

  @State private var selectedAssociation: String = ""

  init() {
    // Start netværksmonitor app-wide (valgfrit)
    NetworkMonitorHandler.shared.startMonitoring { isOnline in
      if isOnline {
        print("Internet is online.")
      } else {
        print("Internet is offline.")
      }
    }
  }

  var body: some Scene {
    WindowGroup {
      ContentView(selectedAssociation: $selectedAssociation)
    }
  }
}
