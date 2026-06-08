import SwiftUI

@main
struct VoiceInkApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var transcriptionManager = TranscriptionManager()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(transcriptionManager)
        } label: {
            Image(systemName: transcriptionManager.isRecording ? "mic.fill" : "mic")
        }
        .menuBarExtraStyle(.window)

        Window("VoiceInk Settings", id: "settings") {
            SettingsView()
                .environmentObject(transcriptionManager)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
