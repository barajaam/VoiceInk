import Foundation
import Speech

class AppleSpeechEngine: ObservableObject {
    private var recognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    @Published var partialResult: String = ""
    @Published var isAuthorized = false

    init() {
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        requestAuthorization()
    }

    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.isAuthorized = (status == .authorized)
            }
        }
    }

    func startRealTimeRecognition(audioEngine: AVAudioEngine? = nil) {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let request = recognitionRequest, let recognizer = recognizer else { return }

        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            if let result = result {
                DispatchQueue.main.async {
                    self.partialResult = result.bestTranscription.formattedString
                }
            }
            if error != nil || (result?.isFinal ?? false) {
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        }
    }

    func appendBuffer(_ buffer: AVAudioPCMBuffer) {
        recognitionRequest?.append(buffer)
    }

    func stopRecognition() -> String {
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        let final = partialResult
        partialResult = ""
        return final
    }

    func transcribeFile(at url: URL) async throws -> String {
        guard let recognizer = recognizer, recognizer.isAvailable else {
            throw TranscriptionError.recognizerUnavailable
        }

        let request = SFSpeechURLRecognitionRequest(url: url)
        request.requiresOnDeviceRecognition = true

        return try await withCheckedThrowingContinuation { continuation in
            recognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                if let result = result, result.isFinal {
                    continuation.resume(returning: result.bestTranscription.formattedString)
                }
            }
        }
    }

    enum TranscriptionError: LocalizedError {
        case recognizerUnavailable

        var errorDescription: String? {
            "Speech recognizer is not available"
        }
    }
}
