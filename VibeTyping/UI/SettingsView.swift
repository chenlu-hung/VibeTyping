import SwiftUI
import Carbon.HIToolbox

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
        .frame(width: 480, height: 360)
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
                    Text("預設路徑: ~/Library/Application Support/VibeTyping/HubCache/")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section {
                HStack {
                    Text("錄音快捷鍵")
                    Spacer()
                    HotkeyRecorderView()
                }
                Text("按下按鈕後，輸入新的快捷鍵組合（需包含修飾鍵）")
                    .font(.caption)
                    .foregroundColor(.secondary)
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

// MARK: - Hotkey Recorder

/// SwiftUI view that wraps an NSView-based keyboard shortcut recorder.
/// Clicking the button enters "recording" mode; the next key press with
/// modifier(s) is captured and saved to AppSettings.
struct HotkeyRecorderView: NSViewRepresentable {
    func makeNSView(context: Context) -> HotkeyRecorderButton {
        let button = HotkeyRecorderButton()
        button.onHotkeyChanged = { keyCode, modifiers in
            let settings = AppSettings.shared
            settings.triggerKeyCode = keyCode
            settings.triggerModifierFlags = UInt(modifiers.rawValue)
            NSLog("VibeTyping: Hotkey changed to keyCode=\(keyCode), modifiers=\(modifiers.rawValue)")
        }
        return button
    }

    func updateNSView(_ nsView: HotkeyRecorderButton, context: Context) {
        nsView.refreshLabel()
    }
}

/// An NSButton that captures the next key event when clicked,
/// recording the key code and modifier flags as a new hotkey.
class HotkeyRecorderButton: NSButton {
    var onHotkeyChanged: ((UInt16, NSEvent.ModifierFlags) -> Void)?
    private var isListening = false
    private var eventMonitor: Any?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupButton()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }

    private func setupButton() {
        bezelStyle = .rounded
        setButtonType(.momentaryPushIn)
        target = self
        action = #selector(toggleListening)
        refreshLabel()

        // Set a reasonable size
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(greaterThanOrEqualToConstant: 140).isActive = true
    }

    func refreshLabel() {
        let settings = AppSettings.shared
        let label = KeyCodeHelper.displayString(
            keyCode: settings.triggerKeyCode,
            modifiers: NSEvent.ModifierFlags(rawValue: UInt(settings.triggerModifierFlags))
        )
        title = isListening ? "按下快捷鍵..." : label
    }

    @objc private func toggleListening() {
        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }

    private func startListening() {
        isListening = true
        refreshLabel()

        // Use a local event monitor to capture key events
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }

            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

            // Escape cancels recording
            if event.keyCode == UInt16(kVK_Escape) {
                self.stopListening()
                return nil
            }

            // Require at least one modifier key (Ctrl, Cmd, Option, Shift)
            let hasModifier = modifiers.contains(.control) ||
                              modifiers.contains(.command) ||
                              modifiers.contains(.option)

            guard hasModifier else {
                // Ignore keystrokes without modifiers (except Escape)
                return nil
            }

            self.onHotkeyChanged?(event.keyCode, modifiers)
            self.stopListening()
            return nil // swallow the event
        }
    }

    private func stopListening() {
        isListening = false
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        refreshLabel()
    }

    deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}

// MARK: - Key Code Helper

/// Converts macOS virtual key codes to human-readable strings.
enum KeyCodeHelper {
    /// Produce a display string like "⌃/" or "⌥⇧A".
    static func displayString(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) -> String {
        var parts: [String] = []

        if modifiers.contains(.control)  { parts.append("⌃") }
        if modifiers.contains(.option)   { parts.append("⌥") }
        if modifiers.contains(.shift)    { parts.append("⇧") }
        if modifiers.contains(.command)  { parts.append("⌘") }

        parts.append(keyName(for: keyCode))
        return parts.joined()
    }

    /// Map common virtual key codes to readable names.
    static func keyName(for keyCode: UInt16) -> String {
        switch Int(keyCode) {
        case kVK_Return:            return "↩"
        case kVK_Tab:               return "⇥"
        case kVK_Space:             return "Space"
        case kVK_Delete:            return "⌫"
        case kVK_ForwardDelete:     return "⌦"
        case kVK_Escape:            return "⎋"
        case kVK_LeftArrow:         return "←"
        case kVK_RightArrow:        return "→"
        case kVK_UpArrow:           return "↑"
        case kVK_DownArrow:         return "↓"
        case kVK_Home:              return "↖"
        case kVK_End:               return "↘"
        case kVK_PageUp:            return "⇞"
        case kVK_PageDown:          return "⇟"
        case kVK_F1:                return "F1"
        case kVK_F2:                return "F2"
        case kVK_F3:                return "F3"
        case kVK_F4:                return "F4"
        case kVK_F5:                return "F5"
        case kVK_F6:                return "F6"
        case kVK_F7:                return "F7"
        case kVK_F8:                return "F8"
        case kVK_F9:                return "F9"
        case kVK_F10:               return "F10"
        case kVK_F11:               return "F11"
        case kVK_F12:               return "F12"
        case kVK_ANSI_A:            return "A"
        case kVK_ANSI_B:            return "B"
        case kVK_ANSI_C:            return "C"
        case kVK_ANSI_D:            return "D"
        case kVK_ANSI_E:            return "E"
        case kVK_ANSI_F:            return "F"
        case kVK_ANSI_G:            return "G"
        case kVK_ANSI_H:            return "H"
        case kVK_ANSI_I:            return "I"
        case kVK_ANSI_J:            return "J"
        case kVK_ANSI_K:            return "K"
        case kVK_ANSI_L:            return "L"
        case kVK_ANSI_M:            return "M"
        case kVK_ANSI_N:            return "N"
        case kVK_ANSI_O:            return "O"
        case kVK_ANSI_P:            return "P"
        case kVK_ANSI_Q:            return "Q"
        case kVK_ANSI_R:            return "R"
        case kVK_ANSI_S:            return "S"
        case kVK_ANSI_T:            return "T"
        case kVK_ANSI_U:            return "U"
        case kVK_ANSI_V:            return "V"
        case kVK_ANSI_W:            return "W"
        case kVK_ANSI_X:            return "X"
        case kVK_ANSI_Y:            return "Y"
        case kVK_ANSI_Z:            return "Z"
        case kVK_ANSI_0:            return "0"
        case kVK_ANSI_1:            return "1"
        case kVK_ANSI_2:            return "2"
        case kVK_ANSI_3:            return "3"
        case kVK_ANSI_4:            return "4"
        case kVK_ANSI_5:            return "5"
        case kVK_ANSI_6:            return "6"
        case kVK_ANSI_7:            return "7"
        case kVK_ANSI_8:            return "8"
        case kVK_ANSI_9:            return "9"
        case kVK_ANSI_Minus:        return "-"
        case kVK_ANSI_Equal:        return "="
        case kVK_ANSI_LeftBracket:  return "["
        case kVK_ANSI_RightBracket: return "]"
        case kVK_ANSI_Backslash:    return "\\"
        case kVK_ANSI_Semicolon:    return ";"
        case kVK_ANSI_Quote:        return "'"
        case kVK_ANSI_Comma:        return ","
        case kVK_ANSI_Period:       return "."
        case kVK_ANSI_Slash:        return "/"
        case kVK_ANSI_Grave:        return "`"
        default:
            // Fallback: try to use the character from TISCopyCurrentKeyboardInputSource
            if let char = characterForKeyCode(keyCode) {
                return char.uppercased()
            }
            return "Key(\(keyCode))"
        }
    }

    /// Use Carbon's UCKeyTranslate to get the character for an unknown key code.
    private static func characterForKeyCode(_ keyCode: UInt16) -> String? {
        let source = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
        guard let layoutDataRef = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else {
            return nil
        }
        let layoutData = unsafeBitCast(layoutDataRef, to: CFData.self)
        let keyboardLayout = unsafeBitCast(CFDataGetBytePtr(layoutData), to: UnsafePointer<UCKeyboardLayout>.self)

        var deadKeyState: UInt32 = 0
        var chars = [UniChar](repeating: 0, count: 4)
        var length: Int = 0

        let status = UCKeyTranslate(
            keyboardLayout,
            keyCode,
            UInt16(kUCKeyActionDown),
            0, // no modifiers for the base character
            UInt32(LMGetKbdType()),
            UInt32(kUCKeyTranslateNoDeadKeysBit),
            &deadKeyState,
            chars.count,
            &length,
            &chars
        )

        guard status == noErr, length > 0 else { return nil }
        return String(utf16CodeUnits: chars, count: length)
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
