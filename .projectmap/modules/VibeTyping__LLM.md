# Module: `VibeTyping/LLM`

## Summary
Optional post-processing step that improves Whisper output quality. `LLMClient` (a Swift actor) sends the raw transcription to any OpenAI-compatible chat completions endpoint, using the API key and model stored in `AppSettings`. `CorrectionPrompt` builds the system/user message pair that instructs the model to fix punctuation and homophone errors without altering meaning.

<!-- projectmap:auto:start (generated — do not edit by hand) -->
## Files (2)
- `VibeTyping/LLM/CorrectionPrompt.swift`
- `VibeTyping/LLM/LLMClient.swift`

## Public symbols (5)
- `struct CorrectionPromptPair` — VibeTyping/LLM/CorrectionPrompt.swift:3
- `enum CorrectionPrompt` — VibeTyping/LLM/CorrectionPrompt.swift:8
- `function build` — VibeTyping/LLM/CorrectionPrompt.swift:9
- `actor LLMClient` — VibeTyping/LLM/LLMClient.swift:4
- `function correctTranscription` — VibeTyping/LLM/LLMClient.swift:9

## Dependencies (imports)
- `Foundation`
<!-- projectmap:auto:end -->
