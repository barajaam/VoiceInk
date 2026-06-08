#!/bin/bash
# Creates VoiceInk.xcodeproj using xcodegen
# Install xcodegen: brew install xcodegen

set -e

cat > project.yml << 'EOF'
name: VoiceInk
options:
  bundleIdPrefix: com.voiceink
  deploymentTarget:
    macOS: "14.0"
  xcodeVersion: "15.0"

packages:
  whisper.cpp:
    url: https://github.com/ggerganov/whisper.cpp
    branch: master
  KeyboardShortcuts:
    url: https://github.com/sindresorhus/KeyboardShortcuts
    from: "2.0.0"

targets:
  VoiceInk:
    type: application
    platform: macOS
    sources:
      - VoiceInk
    settings:
      base:
        INFOPLIST_FILE: VoiceInk/Info.plist
        CODE_SIGN_ENTITLEMENTS: VoiceInk/VoiceInk.entitlements
        PRODUCT_BUNDLE_IDENTIFIER: com.voiceink.app
        MARKETING_VERSION: "1.0.0"
        CURRENT_PROJECT_VERSION: "1"
        ENABLE_HARDENED_RUNTIME: YES
        CODE_SIGN_IDENTITY: "-"
        MACOSX_DEPLOYMENT_TARGET: "14.0"
        LD_RUNPATH_SEARCH_PATHS: "@executable_path/../Frameworks"
    dependencies:
      - package: whisper.cpp
        product: whisper
      - package: KeyboardShortcuts
    info:
      path: VoiceInk/Info.plist
    entitlements:
      path: VoiceInk/VoiceInk.entitlements
EOF

if command -v xcodegen &> /dev/null; then
    xcodegen generate
    echo "✓ VoiceInk.xcodeproj created successfully"
    echo "  Run: open VoiceInk.xcodeproj"
else
    echo "xcodegen not found. Install it with:"
    echo "  brew install xcodegen"
    echo ""
    echo "Or open Package.swift directly in Xcode:"
    echo "  open Package.swift"
fi
