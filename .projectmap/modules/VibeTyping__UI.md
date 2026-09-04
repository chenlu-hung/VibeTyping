# Module: `VibeTyping/UI`

## Summary
All visible UI components. `StatusOverlayPanel` is a floating, borderless `NSPanel` that appears near the cursor to show the current pipeline state (recording / transcribing / correcting), and `ModelDownloadPanel` renders startup progress, switching between the recognition and punctuation stages through `setStage`. `DownloadPanelController` wraps that panel as a `@MainActor` handle the model managers' progress closures can safely capture, and `SettingsView` is a three-tab SwiftUI form covering recognition, punctuation, and LLM correction, plus a `HotkeyRecorderButton` that captures a new trigger key combination directly from the keyboard.

<!-- projectmap:auto:start (generated — do not edit by hand) -->
## Files (3)
- `VibeTyping/UI/ModelDownloadPanel.swift`
- `VibeTyping/UI/SettingsView.swift`
- `VibeTyping/UI/StatusOverlayPanel.swift`

## Public symbols (38)
- `class ModelDownloadPanel` — VibeTyping/UI/ModelDownloadPanel.swift:5
- `function setupUI` — VibeTyping/UI/ModelDownloadPanel.swift:34
- `function setStage` — VibeTyping/UI/ModelDownloadPanel.swift:86
- `function updateProgress` — VibeTyping/UI/ModelDownloadPanel.swift:99
- `function showLoadingModel` — VibeTyping/UI/ModelDownloadPanel.swift:109
- `function showError` — VibeTyping/UI/ModelDownloadPanel.swift:117
- `function dismiss` — VibeTyping/UI/ModelDownloadPanel.swift:124
- `class DownloadPanelController` — VibeTyping/UI/ModelDownloadPanel.swift:137
- `function present` — VibeTyping/UI/ModelDownloadPanel.swift:145
- `function setStage` — VibeTyping/UI/ModelDownloadPanel.swift:154
- `function updateProgress` — VibeTyping/UI/ModelDownloadPanel.swift:158
- `function showLoadingModel` — VibeTyping/UI/ModelDownloadPanel.swift:162
- `function showError` — VibeTyping/UI/ModelDownloadPanel.swift:167
- `function dismiss` — VibeTyping/UI/ModelDownloadPanel.swift:176
- `struct SettingsView` — VibeTyping/UI/SettingsView.swift:4
- `struct HotkeyRecorderView` — VibeTyping/UI/SettingsView.swift:141
- `function makeNSView` — VibeTyping/UI/SettingsView.swift:142
- `function updateNSView` — VibeTyping/UI/SettingsView.swift:153
- `class HotkeyRecorderButton` — VibeTyping/UI/SettingsView.swift:160
- `function setupButton` — VibeTyping/UI/SettingsView.swift:175
- `function refreshLabel` — VibeTyping/UI/SettingsView.swift:187
- `function toggleListening` — VibeTyping/UI/SettingsView.swift:196
- `function startListening` — VibeTyping/UI/SettingsView.swift:204
- `function stopListening` — VibeTyping/UI/SettingsView.swift:236
- `enum KeyCodeHelper` — VibeTyping/UI/SettingsView.swift:255
- `function displayString` — VibeTyping/UI/SettingsView.swift:257
- `function keyName` — VibeTyping/UI/SettingsView.swift:270
- `function characterForKeyCode` — VibeTyping/UI/SettingsView.swift:355
- `class KeyableWindow` — VibeTyping/UI/SettingsView.swift:390
- `class SettingsWindowManager` — VibeTyping/UI/SettingsView.swift:397
- `function showSettingsWindow` — VibeTyping/UI/SettingsView.swift:403
- `function windowWillClose` — VibeTyping/UI/SettingsView.swift:429
- `enum RecordingState` — VibeTyping/UI/StatusOverlayPanel.swift:3
- `class StatusOverlayPanel` — VibeTyping/UI/StatusOverlayPanel.swift:10
- `function setupUI` — VibeTyping/UI/StatusOverlayPanel.swift:37
- `function show` — VibeTyping/UI/StatusOverlayPanel.swift:72
- `function dismiss` — VibeTyping/UI/StatusOverlayPanel.swift:92
- `function positionNearCursor` — VibeTyping/UI/StatusOverlayPanel.swift:97

## Dependencies (imports)
- `Carbon.HIToolbox`
- `Cocoa`
- `SwiftUI`
<!-- projectmap:auto:end -->
