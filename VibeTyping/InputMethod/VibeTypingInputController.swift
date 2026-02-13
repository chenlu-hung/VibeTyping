import Cocoa
import InputMethodKit

@objc(VibeTypingInputController)
class VibeTypingInputController: IMKInputController {

    private var isRecording = false
    private let audioRecorder = AudioRecorder()
    private var statusPanel: StatusOverlayPanel?
    private weak var activeClient: (any IMKTextInput)?

    // MARK: - Lifecycle

    override func activateServer(_ sender: Any!) {
        super.activateServer(sender)
        NSLog("VibeTyping: Server activated")

        // Preload WhisperKit model in background
        Task {
            try? await WhisperKitManager.shared.loadModel()
        }
    }

    override func deactivateServer(_ sender: Any!) {
        super.deactivateServer(sender)
        NSLog("VibeTyping: Server deactivated")

        // Stop recording if active
        if isRecording {
            _ = audioRecorder.stopRecording()
            isRecording = false
            hideStatusPanel()
        }
    }

    // MARK: - Key Event Handling

    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        guard let event = event else { return false }
        guard let client = sender as? (any IMKTextInput) else { return false }

        if event.type == .keyDown && isVoiceInputTrigger(event) {
            toggleRecording(client: client)
            return true
        }

        return false
    }

    private func isVoiceInputTrigger(_ event: NSEvent) -> Bool {
        let settings = AppSettings.shared
        let requiredModifiers = NSEvent.ModifierFlags(rawValue: UInt(settings.triggerModifierFlags))
        let actualModifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        return event.keyCode == settings.triggerKeyCode && actualModifiers.contains(requiredModifiers)
    }

    // MARK: - Recording Toggle

    private func toggleRecording(client: any IMKTextInput) {
        if isRecording {
            stopRecordingAndTranscribe()
        } else {
            startRecording(client: client)
        }
    }

    private func startRecording(client: any IMKTextInput) {
        activeClient = client
        isRecording = true
        showStatusPanel(state: .recording)
        NSLog("VibeTyping: Recording started")

        audioRecorder.startRecording { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if self.isRecording {
                    NSLog("VibeTyping: Silence detected, auto-stopping")
                    self.stopRecordingAndTranscribe()
                }
            }
        }
    }

    private func stopRecordingAndTranscribe() {
        guard isRecording else { return }
        isRecording = false
        let audioSamples = audioRecorder.stopRecording()
        NSLog("VibeTyping: Recording stopped, \(audioSamples.count) samples collected")

        guard !audioSamples.isEmpty else {
            NSLog("VibeTyping: No audio samples collected")
            hideStatusPanel()
            return
        }

        showStatusPanel(state: .transcribing)

        Task {
            // Step 1: Transcribe with WhisperKit
            let rawText = await WhisperKitManager.shared.transcribe(audioSamples: audioSamples)
            NSLog("VibeTyping: Raw transcription: \(rawText)")

            guard !rawText.isEmpty else {
                await MainActor.run { self.hideStatusPanel() }
                return
            }

            // Step 2: LLM correction (if enabled)
            let finalText: String
            if AppSettings.shared.isLLMCorrectionEnabled,
               !AppSettings.shared.llmApiKey.isEmpty {
                await MainActor.run { self.showStatusPanel(state: .correcting) }
                finalText = await LLMClient.shared.correctTranscription(rawText)
                NSLog("VibeTyping: Corrected text: \(finalText)")
            } else {
                finalText = rawText
            }

            // Step 3: Commit text to active application
            await MainActor.run {
                self.commitText(finalText)
                self.hideStatusPanel()
            }
        }
    }

    private func commitText(_ text: String) {
        let client = activeClient ?? (self.client() as? (any IMKTextInput))
        guard let client = client else {
            NSLog("VibeTyping: No client available to commit text")
            return
        }
        client.insertText(text, replacementRange: NSRange(location: NSNotFound, length: 0))
        NSLog("VibeTyping: Text committed: \(text)")
    }

    // MARK: - Status Panel

    private func showStatusPanel(state: RecordingState) {
        if statusPanel == nil {
            statusPanel = StatusOverlayPanel()
        }
        statusPanel?.show(state: state)
    }

    private func hideStatusPanel() {
        statusPanel?.dismiss()
    }

    // MARK: - Menu

    override func menu() -> NSMenu! {
        let menu = NSMenu()

        let settingsItem = NSMenuItem(
            title: "VibeTyping 設定...",
            action: #selector(openSettings(_:)),
            keyEquivalent: ""
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        return menu
    }

    @objc private func openSettings(_ sender: Any?) {
        SettingsWindowManager.shared.showSettingsWindow()
    }
}
