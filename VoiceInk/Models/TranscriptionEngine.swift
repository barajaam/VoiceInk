import Foundation

enum TranscriptionEngineType: String, CaseIterable, Codable {
    case appleSpeech = "Apple Speech"
    case whisper = "Whisper (Local)"
}

enum RecordingState {
    case idle
    case recording
    case transcribing
}
