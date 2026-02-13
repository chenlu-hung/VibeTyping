import AVFoundation
import Accelerate

/// Records audio from the microphone using AVAudioEngine.
/// Captures audio and converts to 16kHz mono Float32 for WhisperKit.
class AudioRecorder {
    private let audioEngine = AVAudioEngine()
    private var audioSamples: [Float] = []
    private var silenceCallback: (() -> Void)?
    private let silenceDetector = SilenceDetector()

    /// The target sample rate expected by WhisperKit
    private let targetSampleRate: Double = 16000

    func startRecording(onSilenceDetected: @escaping () -> Void) {
        audioSamples.removeAll()
        silenceDetector.reset()
        silenceCallback = onSilenceDetected

        let inputNode = audioEngine.inputNode
        let hwFormat = inputNode.outputFormat(forBus: 0)

        // Create target format: 16kHz mono Float32
        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: targetSampleRate,
            channels: 1,
            interleaved: false
        ) else {
            NSLog("VibeTyping: Failed to create target audio format")
            return
        }

        // Create converter from hardware format to target format
        let converter = AVAudioConverter(from: hwFormat, to: targetFormat)

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: hwFormat) { [weak self] buffer, _ in
            guard let self = self else { return }

            let convertedSamples: [Float]
            if let converter = converter {
                convertedSamples = self.convertBuffer(buffer, converter: converter, targetFormat: targetFormat)
            } else {
                // If formats match or converter unavailable, use raw samples
                convertedSamples = self.extractSamples(from: buffer)
            }

            guard !convertedSamples.isEmpty else { return }

            self.audioSamples.append(contentsOf: convertedSamples)

            if self.silenceDetector.detectSilence(samples: convertedSamples) {
                self.silenceCallback?()
            }
        }

        do {
            audioEngine.prepare()
            try audioEngine.start()
            NSLog("VibeTyping: Audio engine started (hw format: \(hwFormat))")
        } catch {
            NSLog("VibeTyping: Failed to start audio engine: \(error)")
        }
    }

    func stopRecording() -> [Float] {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        silenceDetector.reset()
        let samples = audioSamples
        audioSamples.removeAll()
        return samples
    }

    // MARK: - Audio Conversion

    private func convertBuffer(
        _ buffer: AVAudioPCMBuffer,
        converter: AVAudioConverter,
        targetFormat: AVAudioFormat
    ) -> [Float] {
        // Estimate output frame count based on sample rate ratio
        let ratio = targetFormat.sampleRate / buffer.format.sampleRate
        let outputFrameCount = AVAudioFrameCount(Double(buffer.frameLength) * ratio)

        guard let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: targetFormat,
            frameCapacity: outputFrameCount
        ) else { return [] }

        var error: NSError?
        var hasData = true
        converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            if hasData {
                outStatus.pointee = .haveData
                hasData = false
                return buffer
            }
            outStatus.pointee = .noDataNow
            return nil
        }

        if let error = error {
            NSLog("VibeTyping: Audio conversion error: \(error)")
            return []
        }

        return extractSamples(from: outputBuffer)
    }

    private func extractSamples(from buffer: AVAudioPCMBuffer) -> [Float] {
        guard let channelData = buffer.floatChannelData else { return [] }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return [] }

        // Take first channel (mono)
        return Array(UnsafeBufferPointer(start: channelData[0], count: frameLength))
    }
}
