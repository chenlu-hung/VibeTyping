# Module: `VibeTyping/Transcription`

## Summary
Manages the on-device WhisperKit model lifecycle and speech-to-text conversion. `WhisperKitManager` (a Swift actor) handles model discovery in HuggingFace Hub cache or a custom folder, downloads with progress callbacks, loads into memory, and exposes a `transcribe(audioSamples:)` method that returns plain text. It is a singleton shared by both `App` (model setup on launch) and `InputMethod` (transcription during recording).

<!-- projectmap:auto:start (generated — do not edit by hand) -->
## Files (1)
- `VibeTyping/Transcription/WhisperKitManager.swift`

## Public symbols (7)
- `actor WhisperKitManager` — VibeTyping/Transcription/WhisperKitManager.swift:7
- `function isModelDownloaded` — VibeTyping/Transcription/WhisperKitManager.swift:33
- `function downloadModel` — VibeTyping/Transcription/WhisperKitManager.swift:50
- `function loadModel` — VibeTyping/Transcription/WhisperKitManager.swift:72
- `function setupModel` — VibeTyping/Transcription/WhisperKitManager.swift:120
- `function findModelInHubCache` — VibeTyping/Transcription/WhisperKitManager.swift:142
- `function transcribe` — VibeTyping/Transcription/WhisperKitManager.swift:160

## Dependencies (imports)
- `Foundation`
- `Hub`
- `WhisperKit`
<!-- projectmap:auto:end -->
