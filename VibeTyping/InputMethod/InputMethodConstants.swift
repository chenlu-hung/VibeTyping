import Cocoa

enum InputMethodConstants {
    /// Default trigger: Ctrl + ` (backtick, keyCode 50)
    static let defaultTriggerKeyCode: UInt16 = 50
    static let defaultTriggerModifierFlag: UInt = NSEvent.ModifierFlags.control.rawValue

    /// Connection name must match Info.plist InputMethodConnectionName
    static let connectionName = "com.vibetyping.inputmethod.VibeTyping_Connection"
}
