import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var manager: TranscriptionManager

    var body: some View {
        TabView {
            GeneralSettingsView()
                .environmentObject(manager)
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            WhisperSettingsView()
                .environmentObject(manager)
                .tabItem {
                    Label("Whisper", systemImage: "cpu")
                }

            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 450, height: 350)
    }
}

struct GeneralSettingsView: View {
    @EnvironmentObject var manager: TranscriptionManager
    @AppStorage("launchAtLogin") private var launchAtLogin = false

    var body: some View {
        Form {
            Section("Transcription Engine") {
                Picker("Engine", selection: $manager.selectedEngine) {
                    ForEach(TranscriptionEngineType.allCases, id: \.self) { engine in
                        Text(engine.rawValue).tag(engine)
                    }
                }
                .pickerStyle(.segmented)

                if manager.selectedEngine == .appleSpeech {
                    Text("Uses macOS built-in speech recognition. Works offline, good for English.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Uses OpenAI Whisper locally. Best accuracy, multilingual. Requires model download.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Language") {
                Picker("Transcription Language", selection: Binding(
                    get: { manager.whisperEngine.selectedLanguage },
                    set: { manager.whisperEngine.setLanguage($0) }
                )) {
                    ForEach(WhisperEngine.supportedLanguages, id: \.code) { lang in
                        Text(lang.name).tag(lang.code)
                    }
                }
                Text("Select a language or use Auto Detect. Works with Whisper engine only.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Behavior") {
                Toggle("Launch at login", isOn: $launchAtLogin)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct WhisperSettingsView: View {
    @EnvironmentObject var manager: TranscriptionManager
    @State private var downloadProgress: Double = 0
    @State private var isDownloading = false
    @State private var downloadingModel = ""
    @State private var downloadError: String?

    var body: some View {
        Form {
            Section("Current Model") {
                HStack {
                    Text(manager.whisperEngine.isModelLoaded ? manager.whisperEngine.modelName : "None loaded")
                        .font(.headline)
                    Spacer()
                    if manager.whisperEngine.isModelLoaded {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }

            Section("Available Models") {
                ForEach(WhisperEngine.availableModels, id: \.name) { model in
                    ModelRow(
                        model: model,
                        isDownloading: isDownloading && downloadingModel == model.name,
                        progress: downloadingModel == model.name ? downloadProgress : 0,
                        isLoaded: manager.whisperEngine.modelName == model.name,
                        onDownload: { downloadModel(model.name) },
                        onLoad: { loadModel(model.name) }
                    )
                }
            }

            if let error = downloadError {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func downloadModel(_ name: String) {
        isDownloading = true
        downloadingModel = name
        downloadProgress = 0
        downloadError = nil

        Task {
            do {
                try await manager.whisperEngine.downloadModel(name: name) { progress in
                    self.downloadProgress = progress
                }
                isDownloading = false
            } catch {
                downloadError = error.localizedDescription
                isDownloading = false
            }
        }
    }

    private func loadModel(_ name: String) {
        Task {
            do {
                try await manager.whisperEngine.loadModel(name: name)
                UserDefaults.standard.set(name, forKey: "whisperModel")
            } catch {
                downloadError = error.localizedDescription
            }
        }
    }
}

struct ModelRow: View {
    let model: (name: String, size: String)
    let isDownloading: Bool
    let progress: Double
    let isLoaded: Bool
    let onDownload: () -> Void
    let onLoad: () -> Void

    private var isDownloaded: Bool {
        let modelDir = WhisperEngine.modelsDirectory.appendingPathComponent("openai_whisper-\(model.name)")
        return FileManager.default.fileExists(atPath: modelDir.path)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(model.name)
                    .font(.body)
                Text(model.size)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isDownloading {
                ProgressView(value: progress)
                    .frame(width: 80)
            } else if isLoaded {
                Text("Active")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.green.opacity(0.2))
                    .cornerRadius(4)
            } else if isDownloaded {
                Button("Load") { onLoad() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            } else {
                Button("Download") { onDownload() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            AppLogoView()
                .frame(width: 80, height: 80)
                .cornerRadius(16)

            Text("VoiceInk")
                .font(.title)
                .bold()

            Text("Voice-to-text transcription for macOS")
                .foregroundStyle(.secondary)

            Text("Version 1.0.0")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                Text("Developer:")
                    .font(.caption)
                    .bold()
                Text("Mahmoud Barajaa")
                    .font(.caption)
                Text("barajaam@amazon.com")
                    .font(.caption)
                Text("Deployment Engineering")
                    .font(.caption)

                Divider()

                Text("Platform:")
                    .font(.caption)
                    .bold()
                Text("macOS Tahoe or later")
                    .font(.caption)

                Divider()

                Text("Engines:")
                    .font(.caption)
                    .bold()
                Text("• Apple Speech — on-device, English optimized")
                    .font(.caption)
                Text("• Whisper — multilingual, highest accuracy")
                    .font(.caption)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.quaternary)
            .cornerRadius(8)

            Text("\u{00A9} 2026 Mahmoud Barajaa. All rights reserved.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
    }
}

struct AppLogoView: View {
    var body: some View {
        if let resourcePath = Bundle.main.path(forResource: "AppLogo", ofType: "png"),
           let nsImage = NSImage(contentsOfFile: resourcePath) {
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFit()
        } else if let nsImage = NSImage(named: "AppLogo") {
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "waveform")
                .font(.system(size: 48))
                .foregroundStyle(.blue)
        }
    }
}
