# Module: `VibeTyping/Settings`

## Summary
Single source of truth for all user-facing configuration. `AppSettings` is a shared singleton that reads and writes to `UserDefaults.standard`, covering LLM endpoint/key/model, the punctuation toggle and its model override, silence threshold, custom Whisper model folder, and trigger hotkey (key code + modifier flags). All other modules read from this class instead of accessing `UserDefaults` directly.

<!-- projectmap:auto:start (generated — do not edit by hand) -->
## Files (1)
- `VibeTyping/Settings/AppSettings.swift`

## Public symbols (1)
- `class AppSettings` — VibeTyping/Settings/AppSettings.swift:4

## Dependencies (imports)
- `Foundation`
<!-- projectmap:auto:end -->
