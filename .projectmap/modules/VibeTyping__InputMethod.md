# Module: `VibeTyping/InputMethod`

## Summary
The core IMK integration that ties all subsystems together. `VibeTypingInputController` extends `IMKInputController` to intercept keyboard events and trigger the full record → transcribe → punctuate → LLM-correct → commit pipeline on the configurable hotkey. `InputMethodConstants` centralises the bundle connection name and default hotkey values used by `AppSettings`.

<!-- projectmap:auto:start (generated — do not edit by hand) -->
## Files (2)
- `VibeTyping/InputMethod/InputMethodConstants.swift`
- `VibeTyping/InputMethod/VibeTypingInputController.swift`

## Public symbols (14)
- `enum InputMethodConstants` — VibeTyping/InputMethod/InputMethodConstants.swift:3
- `class VibeTypingInputController` — VibeTyping/InputMethod/VibeTypingInputController.swift:5
- `function activateServer` — VibeTyping/InputMethod/VibeTypingInputController.swift:14
- `function deactivateServer` — VibeTyping/InputMethod/VibeTypingInputController.swift:19
- `function handle` — VibeTyping/InputMethod/VibeTypingInputController.swift:33
- `function isVoiceInputTrigger` — VibeTyping/InputMethod/VibeTypingInputController.swift:45
- `function toggleRecording` — VibeTyping/InputMethod/VibeTypingInputController.swift:54
- `function startRecording` — VibeTyping/InputMethod/VibeTypingInputController.swift:62
- `function stopRecordingAndTranscribe` — VibeTyping/InputMethod/VibeTypingInputController.swift:79
- `function commitText` — VibeTyping/InputMethod/VibeTypingInputController.swift:131
- `function showStatusPanel` — VibeTyping/InputMethod/VibeTypingInputController.swift:143
- `function hideStatusPanel` — VibeTyping/InputMethod/VibeTypingInputController.swift:150
- `function menu` — VibeTyping/InputMethod/VibeTypingInputController.swift:156
- `function openSettings` — VibeTyping/InputMethod/VibeTypingInputController.swift:170

## Dependencies (imports)
- `Cocoa`
- `InputMethodKit`
<!-- projectmap:auto:end -->
