import Foundation
import SherpaOnnx

enum PunctuationError: LocalizedError {
    case downloadFailed(Int)
    case extractionFailed(Int32)
    case modelMissing(String)

    var errorDescription: String? {
        switch self {
        case .downloadFailed(let status):
            return "標點模型下載失敗（HTTP \(status)）"
        case .extractionFailed(let status):
            return "標點模型解壓縮失敗（tar 結束碼 \(status)）"
        case .modelMissing(let path):
            return "找不到標點模型：\(path)"
        }
    }
}

/// Restores punctuation in the raw ASR output.
///
/// Breeze-ASR-25 emits no punctuation at all — its Mandarin training data is 10,000
/// hours of synthetic speech whose transcripts carry none, which trains the behaviour
/// out of the underlying Whisper-large-v2. Rather than swap the recogniser (the
/// alternatives are trained on Simplified Chinese and misread Taiwanese vocabulary),
/// this stage bolts FunASR's CT-Transformer punctuation model onto the end of it via
/// sherpa-onnx. The model is a text-to-text tagger: it takes the bare transcript and
/// returns the same characters with ，。？、 inserted, in ~5 ms on CPU.
actor PunctuationManager {
    static let shared = PunctuationManager()

    private var punctuation: SherpaOnnxOfflinePunctuationWrapper?
    private var isLoading = false
    private(set) var isModelReady = false

    private static let archiveName = "sherpa-onnx-punct-ct-transformer-zh-en-vocab272727-2024-04-12-int8"
    private static let modelFileName = "model.int8.onnx"
    private static let downloadURL = URL(
        string: "https://github.com/k2-fsa/sherpa-onnx/releases/download/punctuation-models/\(archiveName).tar.bz2"
    )!

    /// Where the extracted `model.int8.onnx` lives once downloaded.
    private var modelDirectory: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let dir = appSupport.appendingPathComponent("VibeTyping/Punctuation")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// The model file to load: the user's own copy if they pointed at one, else the download.
    private var modelPath: String {
        if let custom = AppSettings.shared.customPunctuationModel, !custom.isEmpty {
            return custom
        }
        return modelDirectory.appendingPathComponent(Self.modelFileName).path
    }

    func isModelDownloaded() -> Bool {
        FileManager.default.fileExists(atPath: modelPath)
    }

    /// Download the release tarball and extract the single model file out of it.
    func downloadModel(progressCallback: @escaping (Double) -> Void) async throws {
        NSLog("VibeTyping: Downloading punctuation model from \(Self.downloadURL)")

        let archive = try await ProgressiveDownloader.download(
            from: Self.downloadURL,
            progressCallback: progressCallback
        )
        defer { try? FileManager.default.removeItem(at: archive) }

        let staging = FileManager.default.temporaryDirectory
            .appendingPathComponent("VibeTypingPunct-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: staging) }

        let tar = Process()
        tar.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        tar.arguments = ["-xjf", archive.path, "-C", staging.path]
        try tar.run()
        tar.waitUntilExit()
        guard tar.terminationStatus == 0 else {
            throw PunctuationError.extractionFailed(tar.terminationStatus)
        }

        let extracted = staging
            .appendingPathComponent(Self.archiveName)
            .appendingPathComponent(Self.modelFileName)
        guard FileManager.default.fileExists(atPath: extracted.path) else {
            throw PunctuationError.modelMissing(extracted.path)
        }

        let destination = modelDirectory.appendingPathComponent(Self.modelFileName)
        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.moveItem(at: extracted, to: destination)
        NSLog("VibeTyping: Punctuation model ready at \(destination.path)")
    }

    func loadModel() throws {
        guard punctuation == nil, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        let path = modelPath
        guard FileManager.default.fileExists(atPath: path) else {
            throw PunctuationError.modelMissing(path)
        }

        var config = sherpaOnnxOfflinePunctuationConfig(
            model: sherpaOnnxOfflinePunctuationModelConfig(
                ctTransformer: path,
                numThreads: 2,
                debug: 0,
                provider: "cpu"
            )
        )
        punctuation = SherpaOnnxOfflinePunctuationWrapper(config: &config)
        isModelReady = true
        NSLog("VibeTyping: Punctuation model loaded from \(path)")
    }

    /// Full setup: download if needed (with progress), then load.
    func setupModel(progressCallback: @escaping (Double) -> Void) async throws {
        if isModelDownloaded() {
            progressCallback(1.0)
        } else {
            try await downloadModel(progressCallback: progressCallback)
        }
        try loadModel()
    }

    /// Insert punctuation into `text`, preserving its original spacing.
    ///
    /// Returns `text` untouched on any failure — a transcript without punctuation is
    /// worth committing, a lost one is not.
    func addPunctuation(to text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return text }

        if punctuation == nil {
            do {
                try loadModel()
            } catch {
                NSLog("VibeTyping: Punctuation model unavailable: \(error)")
                return text
            }
        }
        guard let punctuation = punctuation else { return text }

        let punctuated = punctuation.addPunct(text: trimmed)
        guard !punctuated.isEmpty else {
            NSLog("VibeTyping: Punctuation returned empty output, keeping raw text")
            return text
        }
        return PunctuationSpacing.restore(original: trimmed, punctuated: punctuated)
    }
}

/// A one-shot URLSession download that reports byte progress.
///
/// `URLSession.download(from:)` gives no progress and `AsyncBytes` would walk 65 MB one
/// byte at a time, so this drops to the delegate API and hands back the temporary file.
private final class ProgressiveDownloader: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    private let progressCallback: (Double) -> Void
    private var continuation: CheckedContinuation<URL, Error>?

    private init(progressCallback: @escaping (Double) -> Void) {
        self.progressCallback = progressCallback
    }

    static func download(
        from url: URL,
        progressCallback: @escaping (Double) -> Void
    ) async throws -> URL {
        let downloader = ProgressiveDownloader(progressCallback: progressCallback)
        return try await withCheckedThrowingContinuation { continuation in
            downloader.continuation = continuation
            let session = URLSession(
                configuration: .default,
                delegate: downloader,
                delegateQueue: nil
            )
            session.downloadTask(with: url).resume()
            session.finishTasksAndInvalidate()
        }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard totalBytesExpectedToWrite > 0 else { return }
        progressCallback(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite))
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        if let response = downloadTask.response as? HTTPURLResponse, response.statusCode != 200 {
            continuation?.resume(throwing: PunctuationError.downloadFailed(response.statusCode))
            continuation = nil
            return
        }

        // The delegate's temporary file is deleted the moment this method returns.
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent("VibeTypingPunct-\(UUID().uuidString).tar.bz2")
        do {
            try FileManager.default.moveItem(at: location, to: destination)
            continuation?.resume(returning: destination)
        } catch {
            continuation?.resume(throwing: error)
        }
        continuation = nil
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error else { return }
        continuation?.resume(throwing: error)
        continuation = nil
    }
}
