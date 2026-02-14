import SwiftUI

struct SettingsView: View {
    @AppStorage("llmEndpoint") private var llmEndpoint: String = "https://api.openai.com"
    @AppStorage("llmApiKey") private var llmApiKey: String = ""
    @AppStorage("llmModel") private var llmModel: String = "gpt-4o-mini"
    @AppStorage("isLLMCorrectionEnabled") private var isLLMCorrectionEnabled: Bool = true
    @AppStorage("silenceDuration") private var silenceDuration: Double = 1.5
    @AppStorage("customModelFolder") private var customModelFolder: String = ""

    var body: some View {
        TabView {
            asrSettingsTab
                .tabItem {
                    Label("語音辨識", systemImage: "waveform")
                }

            llmSettingsTab
                .tabItem {
                    Label("LLM 校正", systemImage: "text.badge.checkmark")
                }
        }
        .padding(20)
        .frame(width: 480, height: 320)
    }

    // MARK: - ASR Settings Tab

    private var asrSettingsTab: some View {
        Form {
            Section {
                HStack {
                    Text("靜音偵測秒數")
                    Spacer()
                    Text(String(format: "%.1f 秒", silenceDuration))
                        .foregroundColor(.secondary)
                }
                Slider(value: $silenceDuration, in: 0.5...3.0, step: 0.1)

                VStack(alignment: .leading, spacing: 4) {
                    Text("自訂模型資料夾")
                    TextField("留空使用預設路徑", text: $customModelFolder)
                        .textFieldStyle(.roundedBorder)
                    Text("預設路徑: ~/Library/Application Support/VibeTyping/Models/")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("快捷鍵")
                        .font(.headline)
                    Text("Ctrl + / 開始/停止錄音")
                        .foregroundColor(.secondary)
                    Text("說完話後會自動停止錄音")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - LLM Settings Tab

    private var llmSettingsTab: some View {
        Form {
            Section {
                Toggle("啟用 LLM 校正", isOn: $isLLMCorrectionEnabled)
            }

            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("API Endpoint")
                    TextField("https://api.openai.com", text: $llmEndpoint)
                        .textFieldStyle(.roundedBorder)
                    Text("支援任何 OpenAI 相容 API 端點")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("API Key")
                    SecureField("sk-...", text: $llmApiKey)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Model")
                    TextField("gpt-4o-mini", text: $llmModel)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .disabled(!isLLMCorrectionEnabled)
            .opacity(isLLMCorrectionEnabled ? 1.0 : 0.5)
        }
    }
}

// MARK: - KeyableWindow

/// Custom NSWindow subclass that can always become key window.
/// Required because InputMethodKit apps run as LSBackgroundOnly,
/// and the default NSWindow refuses keyboard focus in that mode.
private class KeyableWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

// MARK: - Settings Window Manager

class SettingsWindowManager: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowManager()

    private var settingsWindow: NSWindow?
    private var previousActivationPolicy: NSApplication.ActivationPolicy = .accessory

    func showSettingsWindow() {
        if let window = settingsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Save current activation policy and switch to .regular
        // so the app can receive keyboard focus for text fields
        previousActivationPolicy = NSApp.activationPolicy()
        NSApp.setActivationPolicy(.regular)

        let hostingController = NSHostingController(rootView: SettingsView())
        let window = KeyableWindow(contentViewController: hostingController)
        window.title = "VibeTyping 設定"
        window.styleMask = [.titled, .closable]
        window.delegate = self
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        settingsWindow = window
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        // Restore the previous activation policy when settings window closes
        NSApp.setActivationPolicy(previousActivationPolicy)
        settingsWindow = nil
    }
}
