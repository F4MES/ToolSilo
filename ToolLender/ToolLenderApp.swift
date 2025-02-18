import SwiftUI
import Firebase
import FirebaseFirestore
import Network

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Aktiver offline persistence for Firestore
        let db = Firestore.firestore()
        let settings = db.settings
        settings.isPersistenceEnabled = true // Aktiver offline persistence
        db.settings = settings
        
        return true
    }
}

@main
struct ToolLenderApp: App {
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
