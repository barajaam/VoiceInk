# VoiceInk

A macOS menu bar app for voice-to-text transcription. Supports both Apple Speech (built-in) and OpenAI Whisper (local) engines.

## Features

- **Dual Engine**: Switch between Apple Speech (fast, built-in) and Whisper (accurate, multilingual)
- **Global Hotkey**: Press Cmd+Shift+Space (customizable) to start/stop recording from any app
- **Menu Bar Control**: Click the mic icon to toggle recording
- **Auto-Paste**: Transcribed text is automatically pasted into the active text field
- **Real-time Preview**: See partial transcription as you speak (Apple Speech engine)
- **Fully Offline**: Both engines work without internet
- **Model Management**: Download and switch between Whisper models (tiny → large)

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15+
- Microphone access
- Accessibility permission (for auto-paste)

## Build & Run

### Option 1: Xcode

1. Open the project in Xcode:
   ```bash
   cd VoiceInk
   open Package.swift
   ```

2. Select "My Mac" as the run destination

3. Build and run (Cmd+R)

### Option 2: Command Line

```bash
swift build -c release
```

## Setup

1. **First Launch**: Grant microphone and speech recognition permissions when prompted
2. **Accessibility**: Go to System Settings → Privacy & Security → Accessibility → Enable VoiceInk
   (Required for auto-paste to work)
3. **Whisper Engine**: If using Whisper, go to Settings → Whisper tab → Download a model

## Usage

1. Press **Cmd+Shift+Space** (or click the menu bar mic icon)
2. Speak clearly
3. Press the hotkey again (or click Stop)
4. Text is automatically pasted into your active app

## Whisper Models

| Model | Size | Speed | Accuracy |
|-------|------|-------|----------|
| tiny | 75 MB | Fastest | Good |
| base | 142 MB | Fast | Better |
| small | 466 MB | Medium | Great |
| medium | 1.5 GB | Slow | Excellent |
| large-v3 | 3.1 GB | Slowest | Best |

Recommended: **base** for everyday use, **small** for important transcriptions.

## Architecture

```
VoiceInk/
├── VoiceInkApp.swift          # App entry point, menu bar setup
├── Models/
│   └── TranscriptionEngine.swift   # Engine type enum
├── Services/
│   ├── AudioRecorder.swift         # Audio capture (16kHz mono WAV)
│   ├── AppleSpeechEngine.swift     # Apple Speech framework integration
│   ├── WhisperEngine.swift         # whisper.cpp integration
│   ├── TextPaster.swift            # Simulates Cmd+V paste
│   └── TranscriptionManager.swift  # Orchestrates recording + transcription
└── Views/
    ├── MenuBarView.swift           # Menu bar popover UI
    └── SettingsView.swift          # Settings window (General, Whisper, About)
```

## Permissions Explained

- **Microphone**: Records your voice
- **Speech Recognition**: Apple Speech engine
- **Accessibility**: Simulates keyboard events to paste text
- **Network** (optional): Only used to download Whisper models
