import AVFoundation
import Foundation

class AudioRecorder: NSObject, ObservableObject {
    private var audioEngine = AVAudioEngine()
    private var audioFile: AVAudioFile?
    private var recordingURL: URL?

    @Published var isRecording = false
    @Published var audioLevel: Float = 0.0

    var onAudioBufferReceived: ((AVAudioPCMBuffer) -> Void)?

    func startRecording() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let url = tempDir.appendingPathComponent("voiceink_\(UUID().uuidString).wav")
        recordingURL = url

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        let outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16000,
            channels: 1,
            interleaved: false
        )!

        guard let converter = AVAudioConverter(from: recordingFormat, to: outputFormat) else {
            throw RecorderError.converterCreationFailed
        }

        audioFile = try AVAudioFile(forWriting: url, settings: outputFormat.settings)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            guard let self = self else { return }

            let frameCount = AVAudioFrameCount(
                Double(buffer.frameLength) * 16000.0 / buffer.format.sampleRate
            )
            guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: frameCount) else { return }

            var error: NSError?
            converter.convert(to: convertedBuffer, error: &error) { _, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }

            if error == nil {
                try? self.audioFile?.write(from: convertedBuffer)
                self.onAudioBufferReceived?(convertedBuffer)

                if let channelData = buffer.floatChannelData?[0] {
                    let frames = Int(buffer.frameLength)
                    let rms = sqrt(
                        (0..<frames).reduce(Float(0)) { sum, i in
                            sum + channelData[i] * channelData[i]
                        } / Float(frames)
                    )
                    DispatchQueue.main.async {
                        self.audioLevel = rms
                    }
                }
            }
        }

        audioEngine.prepare()
        try audioEngine.start()

        DispatchQueue.main.async {
            self.isRecording = true
        }

        return url
    }

    func stopRecording() -> URL? {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        audioFile = nil

        DispatchQueue.main.async {
            self.isRecording = false
            self.audioLevel = 0.0
        }

        return recordingURL
    }

    enum RecorderError: LocalizedError {
        case converterCreationFailed

        var errorDescription: String? {
            switch self {
            case .converterCreationFailed:
                return "Failed to create audio format converter"
            }
        }
    }
}
