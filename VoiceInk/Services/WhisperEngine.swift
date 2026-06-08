import Foundation
import WhisperKit
import AVFoundation

class WhisperEngine: ObservableObject {
    private var whisperKit: WhisperKit?
    @Published var isModelLoaded = false
    @Published var modelName: String = "None"
    @Published var progress: Double = 0.0

    static let availableModels: [(name: String, size: String)] = [
        ("tiny", "75 MB"),
        ("base", "142 MB"),
        ("small", "466 MB"),
        ("medium", "1.5 GB"),
        ("large-v3", "3.1 GB"),
    ]

    static let modelsDirectory: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("VoiceInk/Models", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    func isModelDownloaded(name: String) -> Bool {
        let modelDir = Self.modelsDirectory.appendingPathComponent("openai_whisper-\(name)")
        return FileManager.default.fileExists(atPath: modelDir.path)
    }

    func loadModel(name: String) async throws {
        let modelDir = Self.modelsDirectory.appendingPathComponent("openai_whisper-\(name)")

        let config = WhisperKitConfig(
            model: "openai_whisper-\(name)",
            downloadBase: Self.modelsDirectory,
            modelFolder: isModelDownloaded(name: name) ? modelDir.path : nil,
            verbose: false,
            prewarm: true
        )

        let kit = try await WhisperKit(config)

        await MainActor.run {
            self.whisperKit = kit
            self.isModelLoaded = true
            self.modelName = name
            UserDefaults.standard.set(name, forKey: "whisperModel")
        }
    }

    @Published var selectedLanguage: String = UserDefaults.standard.string(forKey: "whisperLanguage") ?? "auto"

    static let supportedLanguages: [(code: String, name: String)] = [
        ("auto", "Auto Detect"),
        ("en", "English"),
        ("ar", "Arabic"),
        ("zh", "Chinese"),
        ("fr", "French"),
        ("de", "German"),
        ("hi", "Hindi"),
        ("it", "Italian"),
        ("ja", "Japanese"),
        ("ko", "Korean"),
        ("pt", "Portuguese"),
        ("ru", "Russian"),
        ("es", "Spanish"),
        ("tr", "Turkish"),
        ("uk", "Ukrainian"),
        ("vi", "Vietnamese"),
    ]

    func setLanguage(_ code: String) {
        selectedLanguage = code
        UserDefaults.standard.set(code, forKey: "whisperLanguage")
    }

    func transcribe(audioURL: URL) async throws -> String {
        guard let whisperKit = whisperKit else {
            throw WhisperError.noModelLoaded
        }

        var options = DecodingOptions()
        if selectedLanguage != "auto" {
            options.language = selectedLanguage
        }

        let results = try await whisperKit.transcribe(audioPath: audioURL.path, decodeOptions: options)

        let text = results.map { $0.text }.joined(separator: " ")
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func downloadModel(name: String, progressHandler: @escaping (Double) -> Void) async throws {
        await MainActor.run { progressHandler(0.1) }

        let config = WhisperKitConfig(
            model: "openai_whisper-\(name)",
            downloadBase: Self.modelsDirectory,
            verbose: false,
            prewarm: true
        )

        let kit = try await WhisperKit(config)

        await MainActor.run {
            self.whisperKit = kit
            self.isModelLoaded = true
            self.modelName = name
            UserDefaults.standard.set(name, forKey: "whisperModel")
            progressHandler(1.0)
        }
    }

    enum WhisperError: LocalizedError {
        case noModelLoaded
        case transcriptionFailed

        var errorDescription: String? {
            switch self {
            case .noModelLoaded: return "No model loaded. Download and load a model first."
            case .transcriptionFailed: return "Transcription failed"
            }
        }
    }
}
