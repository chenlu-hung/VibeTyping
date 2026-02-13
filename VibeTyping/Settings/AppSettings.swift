import Foundation

/// Centralized settings access via UserDefaults.
class AppSettings {
    static let shared = AppSettings()

    private let defaults = UserDefaults.standard

    // MARK: - LLM Settings

    var llmEndpoint: String {
        get { defaults.string(forKey: "llmEndpoint") ?? "https://api.openai.com" }
        set { defaults.set(newValue, forKey: "llmEndpoint") }
    }

    var llmApiKey: String {
        get { defaults.string(forKey: "llmApiKey") ?? "" }
        set { defaults.set(newValue, forKey: "llmApiKey") }
    }

    var llmModel: String {
        get { defaults.string(forKey: "llmModel") ?? "gpt-4o-mini" }
        set { defaults.set(newValue, forKey: "llmModel") }
    }

    var isLLMCorrectionEnabled: Bool {
        get {
            if defaults.object(forKey: "isLLMCorrectionEnabled") == nil {
                return true // default on
            }
            return defaults.bool(forKey: "isLLMCorrectionEnabled")
        }
        set { defaults.set(newValue, forKey: "isLLMCorrectionEnabled") }
    }

    // MARK: - Audio Settings

    var silenceDuration: TimeInterval {
        get {
            let val = defaults.double(forKey: "silenceDuration")
            return val > 0 ? val : 1.5
        }
        set { defaults.set(newValue, forKey: "silenceDuration") }
    }

    // MARK: - Model Settings

    var customModelFolder: String? {
        get {
            let val = defaults.string(forKey: "customModelFolder")
            return (val?.isEmpty ?? true) ? nil : val
        }
        set { defaults.set(newValue, forKey: "customModelFolder") }
    }

    // MARK: - Trigger Key Settings

    var triggerKeyCode: UInt16 {
        get {
            let val = defaults.integer(forKey: "triggerKeyCode")
            return val > 0 ? UInt16(val) : InputMethodConstants.defaultTriggerKeyCode
        }
        set { defaults.set(Int(newValue), forKey: "triggerKeyCode") }
    }

    var triggerModifierFlags: UInt {
        get {
            let val = defaults.integer(forKey: "triggerModifierFlags")
            return val > 0 ? UInt(val) : InputMethodConstants.defaultTriggerModifierFlag
        }
        set { defaults.set(Int(newValue), forKey: "triggerModifierFlags") }
    }
}
