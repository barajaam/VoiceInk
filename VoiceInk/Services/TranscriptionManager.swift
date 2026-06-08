import Foundation
import Combine
import SwiftUI

class TranscriptionManager: ObservableObject {
    @Published var isRecording = false
    @Published var recordingState: RecordingState = .idle
    @Published var lastTranscription: String = ""
    @Published var partialText: String = ""
    @Published var errorMessage: String?
    @Published var selectedEngine: TranscriptionEngineType = .appleSpeech {
        didSet {
            UserDefaults.standard.set(selectedEngine.rawValue, forKey: "selectedEngine")
        }
    }

    private let audioRecorder = AudioRecorder()
    let appleSpeechEngine = AppleSpeechEngine()
    let whisperEngine = WhisperEngine()
    private var recordingURL: URL?
    private var cancellables = Set<AnyCancellable>()

    init() {
        if let saved = UserDefaults.standard.string(forKey: "selectedEngine"),
           let engine = TranscriptionEngineType(rawValue: saved) {
            selectedEngine = engine
        }

        TextPaster.startTrackingActiveApp()
        setupBindings()
        setupHotkey()
        loadWhisperModelIfNeeded()
    }

    private func setupHotkey() {
        HotkeyManager.shared.register { [weak self] in
            self?.toggleRecording()
        }
    }

    private func setupBindings() {
        audioRecorder.$isRecording
            .receive(on: DispatchQueue.main)
            .assign(to: &$isRecording)

        appleSpeechEngine.$partialResult
            .receive(on: DispatchQueue.main)
            .assign(to: &$partialText)
    }

    private func loadWhisperModelIfNeeded() {
        if let modelName = UserDefaults.standard.string(forKey: "whisperModel") {
            Task {
                try? await whisperEngine.loadModel(name: modelName)
            }
        }
    }

    func toggleRecording() {
        if recordingState == .idle {
            startRecording()
        } else if recordingState == .recording {
            stopRecording()
        }
    }

    func startRecording() {
        errorMessage = nil
        do {
            recordingURL = try audioRecorder.startRecording()
            recordingState = .recording

            if selectedEngine == .appleSpeech {
                appleSpeechEngine.startRealTimeRecognition()
                audioRecorder.onAudioBufferReceived = { [weak self] buffer in
                    self?.appleSpeechEngine.appendBuffer(buffer)
                }
            }

            playSound(.begin)
        } catch {
            errorMessage = error.localizedDescription
            recordingState = .idle
        }
    }

    func stopRecording() {
        let url = audioRecorder.stopRecording()
        audioRecorder.onAudioBufferReceived = nil
        recordingState = .transcribing

        playSound(.end)

        Task { @MainActor in
            do {
                NSLog("VoiceInk: Transcribing with engine: \(selectedEngine.rawValue)")
                let text: String
                switch selectedEngine {
                case .appleSpeech:
                    text = appleSpeechEngine.stopRecognition()
                    NSLog("VoiceInk: Apple Speech result: '\(text)'")
                case .whisper:
                    guard let audioURL = url else {
                        NSLog("VoiceInk: No audio file")
                        errorMessage = "No audio file recorded"
                        recordingState = .idle
                        return
                    }
                    NSLog("VoiceInk: Transcribing with Whisper...")
                    text = try await whisperEngine.transcribe(audioURL: audioURL)
                    NSLog("VoiceInk: Whisper result: '\(text)'")
                }

                if !text.isEmpty {
                    NSLog("VoiceInk: Pasting text: '\(text)'")
                    lastTranscription = text
                    TextPaster.pasteText(text)
                } else {
                    NSLog("VoiceInk: Text was empty, nothing to paste")
                }

                recordingState = .idle
                cleanupTempFile(url)
            } catch {
                NSLog("VoiceInk: Error: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                recordingState = .idle
                cleanupTempFile(url)
            }
        }
    }

    private func cleanupTempFile(_ url: URL?) {
        guard let url = url else { return }
        try? FileManager.default.removeItem(at: url)
    }

    private func playSound(_ type: SoundType) {
        switch type {
        case .begin:
            NSSound(named: "Tink")?.play()
        case .end:
            NSSound(named: "Pop")?.play()
        }
    }

    private enum SoundType {
        case begin, end
    }
}
