import AppKit
import Carbon

class TextPaster {
    private static var previousApp: NSRunningApplication?
    private static var observer: Any?

    static func startTrackingActiveApp() {
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            if app.bundleIdentifier != Bundle.main.bundleIdentifier {
                previousApp = app
            }
        }

        if let front = NSWorkspace.shared.frontmostApplication,
           front.bundleIdentifier != Bundle.main.bundleIdentifier {
            previousApp = front
        }
    }

    static func pasteText(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        NSLog("VoiceInk: Text copied to clipboard, switching to: \(previousApp?.localizedName ?? "nil")")

        // Hide VoiceInk
        NSApp.hide(nil)

        // Switch to previous app
        if let app = previousApp {
            app.activate()
        }

        // Wait for app switch then paste using CGEvent
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let vKeyCode: CGKeyCode = 0x09 // V key

            guard let source = CGEventSource(stateID: .hidSystemState) else {
                NSLog("VoiceInk: Failed to create event source")
                return
            }

            guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
                  let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) else {
                NSLog("VoiceInk: Failed to create key events")
                return
            }

            keyDown.flags = .maskCommand
            keyUp.flags = .maskCommand

            keyDown.post(tap: .cgSessionEventTap)
            keyUp.post(tap: .cgSessionEventTap)

            NSLog("VoiceInk: Paste event sent")
        }
    }
}
