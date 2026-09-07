# Module: `VibeTyping/App`

## Summary
Bootstrap layer for the macOS Input Method Extension. `AppDelegate` registers the `IMKServer` on launch, then walks two model stages — speech recognition, then punctuation — driving `DownloadPanelController` whenever either has to come over the network; a failed punctuation download is logged and skipped rather than treated as fatal, so only a broken recogniser aborts startup. `NSManualApplication` overrides `NSApplication` to enable full keyboard events inside the input method process; `main.swift` is the binary entry point.

<!-- projectmap:auto:start (generated — do not edit by hand) -->
## Files (3)
- `VibeTyping/App/AppDelegate.swift`
- `VibeTyping/App/NSManualApplication.swift`
- `VibeTyping/App/main.swift`

## Public symbols (6)
- `class AppDelegate` — VibeTyping/App/AppDelegate.swift:4
- `function applicationDidFinishLaunching` — VibeTyping/App/AppDelegate.swift:8
- `function setupModelsOnLaunch` — VibeTyping/App/AppDelegate.swift:27
- `function setupTranscriptionModel` — VibeTyping/App/AppDelegate.swift:52
- `function setupPunctuationModel` — VibeTyping/App/AppDelegate.swift:79
- `class NSManualApplication` — VibeTyping/App/NSManualApplication.swift:3

## Dependencies (imports)
- `Cocoa`
- `InputMethodKit`
<!-- projectmap:auto:end -->
