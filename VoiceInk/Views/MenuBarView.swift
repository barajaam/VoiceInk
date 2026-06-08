import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var manager: TranscriptionManager
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 12) {
            headerSection
            statusSection
            controlsSection
            Divider()
            footerSection
        }
        .padding()
        .frame(width: 300)
    }

    private var headerSection: some View {
        HStack {
            Image(systemName: "waveform")
                .font(.title2)
                .foregroundStyle(.blue)
            Text("VoiceInk")
                .font(.headline)
            HStack(spacing: 2) {
                Image(systemName: "command")
                Image(systemName: "control")
                Text("S")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.quaternary)
            .cornerRadius(4)
            Spacer()
            enginePicker
        }
    }

    private var enginePicker: some View {
        Menu {
            ForEach(TranscriptionEngineType.allCases, id: \.self) { engine in
                Button(action: { manager.selectedEngine = engine }) {
                    HStack {
                        Text(engine.rawValue)
                        if manager.selectedEngine == engine {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Text(manager.selectedEngine == .appleSpeech ? "Apple" : "Whisper")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary)
                .cornerRadius(4)
        }
        .menuStyle(.borderlessButton)
    }

    private var statusSection: some View {
        VStack(spacing: 8) {
            recordingIndicator
            if !manager.partialText.isEmpty && manager.recordingState == .recording {
                Text(manager.partialText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let error = manager.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }
        }
    }

    private var recordingIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(stateColor)
                .frame(width: 8, height: 8)
                .overlay {
                    if manager.recordingState == .recording {
                        Circle()
                            .fill(stateColor.opacity(0.5))
                            .frame(width: 16, height: 16)
                            .animation(.easeInOut(duration: 0.8).repeatForever(), value: manager.recordingState)
                    }
                }
            Text(stateText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private var stateColor: Color {
        switch manager.recordingState {
        case .idle: return .gray
        case .recording: return .red
        case .transcribing: return .orange
        }
    }

    private var stateText: String {
        switch manager.recordingState {
        case .idle: return "Ready"
        case .recording: return "Recording..."
        case .transcribing: return "Transcribing..."
        }
    }

    private var controlsSection: some View {
        Button(action: { manager.toggleRecording() }) {
            HStack {
                Image(systemName: manager.recordingState == .recording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.title3)
                Text(manager.recordingState == .recording ? "Stop Recording" : "Start Recording")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent)
        .tint(manager.recordingState == .recording ? .red : .blue)
        .disabled(manager.recordingState == .transcribing)
    }

    private var footerSection: some View {
        HStack {
            Spacer()
            Button("Settings...") {
                openWindow(id: "settings")
                NSApp.activate(ignoringOtherApps: true)
            }
            .font(.caption)
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .font(.caption)
        }
    }
}
