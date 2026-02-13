import Foundation
import WhisperKit

/// Manages WhisperKit model loading and transcription.
/// Uses the Breeze-ASR-25 CoreML model optimized for Taiwanese Mandarin.
actor WhisperKitManager {
    static let shared = WhisperKitManager()

    private var whisperKit: WhisperKit?
    private var isLoading = false

    private var modelDirectory: String {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let dir = appSupport.appendingPathComponent("VibeTyping/Models")

        // Ensure directory exists
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        return dir.path
    }

    /// Load the WhisperKit model. Downloads on first use.
    func loadModel() async throws {
        guard whisperKit == nil, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        NSLog("VibeTyping: Loading WhisperKit model...")

        // Check for user-specified custom model folder
        let customFolder = AppSettings.shared.customModelFolder
        let folder = customFolder.flatMap { $0.isEmpty ? nil : $0 } ?? modelDirectory

        let config = WhisperKitConfig(
            model: "Breeze-ASR-25",
            modelRepo: "aoiandroid/Breeze-ASR-25_coreml",
            modelFolder: folder,
            computeOptions: ModelComputeOptions(
                audioEncoderCompute: .cpuAndNeuralEngine,
                textDecoderCompute: .cpuAndNeuralEngine
            ),
            verbose: false,
            logLevel: .error,
            prewarm: true,
            load: true,
            download: true
        )

        whisperKit = try await WhisperKit(config)
        NSLog("VibeTyping: WhisperKit model loaded successfully")
    }

    /// Transcribe audio samples (16kHz mono Float32) to text.
    func transcribe(audioSamples: [Float]) async -> String {
        // Ensure model is loaded
        if whisperKit == nil {
            do {
                try await loadModel()
            } catch {
                NSLog("VibeTyping: Failed to load model: \(error)")
                return ""
            }
        }

        guard let whisperKit = whisperKit else {
            NSLog("VibeTyping: WhisperKit not available")
            return ""
        }

        do {
            let options = DecodingOptions(
                task: .transcribe,
                language: "zh"
            )

            let results: [TranscriptionResult] = try await whisperKit.transcribe(
                audioArray: audioSamples,
                decodeOptions: options
            )

            let text = results.map(\.text).joined(separator: "")
                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

            return text
        } catch {
            NSLog("VibeTyping: Transcription error: \(error)")
            return ""
        }
    }
}
