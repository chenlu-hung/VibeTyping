import Foundation

/// Energy-based voice activity detector that detects when the user stops speaking.
/// Only triggers after speech has been detected first, to avoid false positives on ambient noise.
class SilenceDetector {
    private var silenceThreshold: Float = 0.01
    private var silenceDurationThreshold: TimeInterval = 1.5
    private var silenceStartTime: Date?
    private var hasSpeechStarted = false

    init() {
        let settings = AppSettings.shared
        self.silenceDurationThreshold = settings.silenceDuration
    }

    /// Returns true when silence is detected after speech has occurred.
    func detectSilence(samples: [Float]) -> Bool {
        guard !samples.isEmpty else { return false }

        let rms = sqrt(samples.map { $0 * $0 }.reduce(0, +) / Float(samples.count))

        if rms > silenceThreshold {
            hasSpeechStarted = true
            silenceStartTime = nil
            return false
        }

        // Only trigger after speech has actually started
        guard hasSpeechStarted else { return false }

        if silenceStartTime == nil {
            silenceStartTime = Date()
        }

        if let start = silenceStartTime,
           Date().timeIntervalSince(start) >= silenceDurationThreshold {
            return true
        }

        return false
    }

    func reset() {
        silenceStartTime = nil
        hasSpeechStarted = false
    }
}
