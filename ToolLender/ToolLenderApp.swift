import SwiftUI
import Firebase
import FirebaseFirestore
import Network

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        Task {
            await configureFirestoreAsync()
        }
        
        return true
    }
    
    private func configureFirestoreAsync() async {
        let db = Firestore.firestore()
        let settings = db.settings
    
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        
        // Valider cache-indstillinger i baggrunden
        print("Firestore cache enabled: \(settings.isPersistenceEnabled)")
        print("Cache size: \(settings.cacheSizeBytes)")
        
        db.settings = settings
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
