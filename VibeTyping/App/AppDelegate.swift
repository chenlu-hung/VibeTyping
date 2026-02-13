import Cocoa
import InputMethodKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var server: IMKServer!

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let connectionName = Bundle.main.infoDictionary?["InputMethodConnectionName"] as? String else {
            NSLog("VibeTyping: Failed to read InputMethodConnectionName from Info.plist")
            return
        }
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            NSLog("VibeTyping: Failed to read bundle identifier")
            return
        }

        server = IMKServer(name: connectionName, bundleIdentifier: bundleIdentifier)
        NSLog("VibeTyping: IMKServer started with connection: \(connectionName)")
    }
}
