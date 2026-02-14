import Cocoa
import InputMethodKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var server: IMKServer!
    private var downloadPanel: ModelDownloadPanel?

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

        // Auto-download and load model on launch
        Task {
            await setupModelOnLaunch()
        }
    }

    private func setupModelOnLaunch() async {
        let manager = WhisperKitManager.shared
        let needsDownload = await !manager.isModelDownloaded()

        // Show download panel if model is not yet downloaded
        if needsDownload {
            await MainActor.run {
                let panel = ModelDownloadPanel()
                panel.orderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                self.downloadPanel = panel
                NSLog("VibeTyping: Showing download panel")
            }
        }

        do {
            try await manager.setupModel { [weak self] fraction in
                DispatchQueue.main.async {
                    self?.downloadPanel?.updateProgress(fraction)
                }
            }

            // Show "loading model" state after download completes
            if needsDownload {
                await MainActor.run {
                    self.downloadPanel?.showLoadingModel()
                }
            }

            // Wait briefly so user sees the loading state
            try? await Task.sleep(nanoseconds: 800_000_000)

            await MainActor.run {
                self.downloadPanel?.dismiss()
                self.downloadPanel = nil
                NSLog("VibeTyping: Model setup complete, ready for use")
            }
        } catch {
            NSLog("VibeTyping: Model setup failed: \(error)")
            await MainActor.run {
                // Show error on the panel before dismissing
                if let panel = self.downloadPanel {
                    panel.showError("模型下載失敗：\(error.localizedDescription)")
                    // Keep panel visible for 3 seconds to show error
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        panel.dismiss()
                        self.downloadPanel = nil
                    }
                }
            }
        }
    }
}
