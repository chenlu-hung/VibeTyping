# Module: `VibeTyping/Audio`

## Summary
Handles microphone capture and silence-based auto-stop. `AudioRecorder` opens an AVFoundation capture session on start, accumulates PCM audio into a buffer, and converts tap buffers to 16 kHz mono float samples via the Accelerate framework. `SilenceDetector` monitors RMS energy across frames and fires a callback after a configurable stretch of quiet audio, allowing hands-free stop-on-silence.

<!-- projectmap:auto:start (generated — do not edit by hand) -->
## Files (2)
- `VibeTyping/Audio/AudioRecorder.swift`
- `VibeTyping/Audio/SilenceDetector.swift`

## Public symbols (8)
- `class AudioRecorder` — VibeTyping/Audio/AudioRecorder.swift:6
- `function startRecording` — VibeTyping/Audio/AudioRecorder.swift:15
- `function stopRecording` — VibeTyping/Audio/AudioRecorder.swift:66
- `function convertBuffer` — VibeTyping/Audio/AudioRecorder.swift:77
- `function extractSamples` — VibeTyping/Audio/AudioRecorder.swift:111
- `class SilenceDetector` — VibeTyping/Audio/SilenceDetector.swift:5
- `function detectSilence` — VibeTyping/Audio/SilenceDetector.swift:17
- `function reset` — VibeTyping/Audio/SilenceDetector.swift:43

## Dependencies (imports)
- `AVFoundation`
- `Accelerate`
- `Foundation`
<!-- projectmap:auto:end -->
