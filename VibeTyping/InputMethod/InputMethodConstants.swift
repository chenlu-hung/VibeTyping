import Cocoa

enum InputMethodConstants {
    /// Default trigger: Ctrl + / (slash, keyCode 44)
    static let defaultTriggerKeyCode: UInt16 = 44
    static let defaultTriggerModifierFlag: UInt = NSEvent.ModifierFlags.control.rawValue

    /// Connection name must match Info.plist InputMethodConnectionName
    static let connectionName = "com.vibetyping.inputmethod.VibeTyping_Connection"
}
