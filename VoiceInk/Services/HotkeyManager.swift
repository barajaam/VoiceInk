import AppKit
import Carbon

class HotkeyManager {
    private var eventHotKey: EventHotKeyRef?
    private var onToggle: (() -> Void)?

    static let shared = HotkeyManager()

    private init() {
        eventHotKey = nil
        onToggle = nil
    }

    func register(onToggle: @escaping () -> Void) {
        self.onToggle = onToggle

        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x564B)
        hotKeyID.id = 1

        var hotKeyRef: EventHotKeyRef?

        // Ctrl+Cmd+S
        let modifiers: UInt32 = UInt32(cmdKey | controlKey)
        let keyCode: UInt32 = UInt32(kVK_ANSI_S)

        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        eventHotKey = hotKeyRef

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ -> OSStatus in
            HotkeyManager.shared.onToggle?()
            return noErr
        }, 1, &eventType, nil, nil)
    }

    func unregister() {
        if let hotKey = eventHotKey {
            UnregisterEventHotKey(hotKey)
            eventHotKey = nil
        }
    }
}
