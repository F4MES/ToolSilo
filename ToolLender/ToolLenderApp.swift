import SwiftUI
import FirebaseCore
import Network

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
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
