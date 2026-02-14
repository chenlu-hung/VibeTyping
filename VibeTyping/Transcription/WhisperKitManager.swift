import Foundation
import WhisperKit
import Hub

/// Manages WhisperKit model loading and transcription.
/// Uses the Breeze-ASR-25 CoreML model optimized for Taiwanese Mandarin.
actor WhisperKitManager {
    static let shared = WhisperKitManager()

    private var whisperKit: WhisperKit?
    private var isLoading = false
    private(set) var isModelReady = false

    /// The actual folder path where model files reside (set after download or from custom folder).
    private var resolvedModelFolder: URL?

    private static let modelRepo = "aoiandroid/Breeze-ASR-25_coreml"

    /// Hub download cache directory — HubApi stores files here
    /// in Hub's cache layout: <downloadBase>/models--<repo>/snapshots/<hash>/
    private var downloadBaseURL: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let dir = appSupport.appendingPathComponent("VibeTyping/HubCache")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Check if the model files already exist locally.
    /// Looks in both user custom folder and the Hub cache.
    func isModelDownloaded() -> Bool {
        // Check custom folder first
        if let custom = AppSettings.shared.customModelFolder, !custom.isEmpty {
            let modelFile = URL(fileURLWithPath: custom)
                .appendingPathComponent("AudioEncoder.mlmodelc")
            if FileManager.default.fileExists(atPath: modelFile.path) {
                return true
            }
        }

        // Check Hub cache
        return findModelInHubCache() != nil
    }

    /// Download the model with progress tracking using HubApi directly.
    /// The Breeze-ASR-25_coreml repo has model files at the root (not in a subfolder),
    /// so we cannot use WhisperKit.download() which expects a variant subfolder.
    func downloadModel(progressCallback: @escaping (Double) -> Void) async throws -> URL {
        NSLog("VibeTyping: Downloading model from \(Self.modelRepo)...")

        let hubApi = HubApi(downloadBase: downloadBaseURL)
        let repo = Hub.Repo(id: Self.modelRepo, type: .models)

        // Download model files, configs, and tokenizer (skip .md, .DS_Store, etc.)
        let modelFolder = try await hubApi.snapshot(
            from: repo,
            matching: ["*.mlmodelc/*", "*.json", "*.txt"],
            progressHandler: { progress in
                let fraction = progress.fractionCompleted
                NSLog("VibeTyping: Download progress: \(String(format: "%.1f%%", fraction * 100))")
                progressCallback(fraction)
            }
        )

        NSLog("VibeTyping: Model downloaded to: \(modelFolder.path)")
        return modelFolder
    }

    /// Load the WhisperKit model from a specific folder path.
    func loadModel(from folder: URL? = nil) async throws {
        guard whisperKit == nil, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        NSLog("VibeTyping: Loading WhisperKit model...")

        let modelPath: String

        if let folder = folder {
            // Use the explicitly provided folder (from download result)
            modelPath = folder.path
        } else if let custom = AppSettings.shared.customModelFolder, !custom.isEmpty {
            // Use user-specified custom folder
            modelPath = custom
        } else if let resolved = resolvedModelFolder {
            // Use previously resolved folder
            modelPath = resolved.path
        } else {
            // Try to find it in Hub cache
            if let found = findModelInHubCache() {
                modelPath = found.path
            } else {
                throw WhisperError.modelsUnavailable("Model not found. Please download first.")
            }
        }

        NSLog("VibeTyping: Loading model from: \(modelPath)")

        let config = WhisperKitConfig(
            modelFolder: modelPath,
            computeOptions: ModelComputeOptions(
                audioEncoderCompute: .cpuAndNeuralEngine,
                textDecoderCompute: .cpuAndNeuralEngine
            ),
            verbose: false,
            logLevel: .error,
            prewarm: true,
            load: true,
            download: false
        )

        whisperKit = try await WhisperKit(config)
        isModelReady = true
        NSLog("VibeTyping: WhisperKit model loaded successfully")
    }

    /// Full setup: download if needed (with progress), then load.
    func setupModel(progressCallback: @escaping (Double) -> Void) async throws {
        let modelFolder: URL

        if let custom = AppSettings.shared.customModelFolder, !custom.isEmpty {
            // User specified a custom folder — skip download
            modelFolder = URL(fileURLWithPath: custom)
            progressCallback(1.0)
        } else if let cached = findModelInHubCache() {
            // Already downloaded in Hub cache
            modelFolder = cached
            progressCallback(1.0)
            NSLog("VibeTyping: Found existing model at: \(cached.path)")
        } else {
            // Need to download
            modelFolder = try await downloadModel(progressCallback: progressCallback)
        }

        resolvedModelFolder = modelFolder
        try await loadModel(from: modelFolder)
    }

    /// Search Hub cache directory for existing model files.
    private func findModelInHubCache() -> URL? {
        let hubModelsDir = downloadBaseURL
        if let enumerator = FileManager.default.enumerator(
            at: hubModelsDir,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) {
            for case let fileURL as URL in enumerator {
                if fileURL.lastPathComponent == "AudioEncoder.mlmodelc" {
                    // The model folder is the parent directory of AudioEncoder.mlmodelc
                    return fileURL.deletingLastPathComponent()
                }
            }
        }
        return nil
    }

    /// Transcribe audio samples (16kHz mono Float32) to text.
    func transcribe(audioSamples: [Float]) async -> String {
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
