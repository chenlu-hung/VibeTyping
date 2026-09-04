import Cocoa
import InputMethodKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var server: IMKServer!
    private let downloadPanel = DownloadPanelController()

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

        // Auto-download and load models on launch
        Task {
            await setupModelsOnLaunch()
        }
    }

    private func setupModelsOnLaunch() async {
        let punctuationWanted = AppSettings.shared.isPunctuationEnabled
        let needsWhisper = await !WhisperKitManager.shared.isModelDownloaded()
        let hasPunctuationModel = await PunctuationManager.shared.isModelDownloaded()
        let needsPunctuation = punctuationWanted && !hasPunctuationModel

        // Show the panel only when something actually has to come over the network
        if needsWhisper || needsPunctuation {
            await downloadPanel.present()
        }

        let transcriptionReady = await setupTranscriptionModel(showingProgress: needsWhisper)
        guard transcriptionReady else { return }

        if punctuationWanted {
            await setupPunctuationModel(showingProgress: needsPunctuation)
        }

        // Wait briefly so the user sees the final state
        try? await Task.sleep(nanoseconds: 800_000_000)

        await downloadPanel.dismiss()
        NSLog("VibeTyping: Model setup complete, ready for use")
    }

    private func setupTranscriptionModel(showingProgress: Bool) async -> Bool {
        let panel = downloadPanel
        await panel.setStage(
            title: showingProgress ? "正在下載語音辨識模型..." : "正在載入語音辨識模型...",
            detail: showingProgress ? "Breeze-ASR-25 — 首次使用需下載模型" : "Breeze-ASR-25"
        )

        do {
            try await WhisperKitManager.shared.setupModel { fraction in
                Task { @MainActor in panel.updateProgress(fraction) }
            }

            if showingProgress {
                await panel.showLoadingModel()
            }
            return true
        } catch {
            NSLog("VibeTyping: Model setup failed: \(error)")
            await panel.showError("模型下載失敗：\(error.localizedDescription)")
            return false
        }
    }

    /// Downloads and loads the CT-Transformer punctuation model.
    ///
    /// Failure here is deliberately not fatal: without it dictation still commits text,
    /// it just arrives unpunctuated, which is no worse than before this stage existed.
    private func setupPunctuationModel(showingProgress: Bool) async {
        let panel = downloadPanel
        await panel.setStage(
            title: showingProgress ? "正在下載標點還原模型..." : "正在載入標點還原模型...",
            detail: showingProgress ? "CT-Transformer — 約 65 MB" : "CT-Transformer"
        )

        do {
            try await PunctuationManager.shared.setupModel { fraction in
                Task { @MainActor in panel.updateProgress(fraction) }
            }

            if showingProgress {
                await panel.showLoadingModel()
            }
        } catch {
            NSLog("VibeTyping: Punctuation setup failed, continuing without it: \(error)")
        }
    }
}
