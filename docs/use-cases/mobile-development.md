# Mobile Development Guide

Tools for cross-platform and native mobile development on Mac.

## Tool Stack

| Framework | Requirements |
|-----------|--------------|
| React Native | Node.js, Xcode, Android Studio* |
| Flutter | Flutter SDK*, Xcode, Android Studio* |
| Native iOS | Xcode*, Swift |
| Native Android | Android Studio* |

`*` = Requires manual installation (not included in Mac Dev Machine)

---

## React Native Setup

### Prerequisites

```bash
# Verify Node.js
node --version  # Should be 18+

# Install React Native CLI
npm install -g react-native-cli

# Install Watchman (file watcher)
brew install watchman

# Install CocoaPods (iOS dependencies)
sudo gem install cocoapods
```

### iOS Setup

```bash
# Install Xcode from App Store (manual)
# Then install command line tools
xcode-select --install

# Accept license
sudo xcodebuild -license accept
```

### Create Project

```bash
npx react-native@latest init MyApp
cd MyApp

# Run iOS
npx react-native run-ios

# Run Android (requires Android Studio)
npx react-native run-android
```

### Expo (Easier Alternative)

```bash
# Create with Expo
npx create-expo-app MyApp
cd MyApp

# Start
npx expo start

# Run on device
# Scan QR code with Expo Go app
```

---

## Flutter Setup

### Installation (Manual)

```bash
# Download Flutter SDK
# https://flutter.dev/docs/get-started/install/macos

# Add to PATH (~/.zshrc)
export PATH="$PATH:$HOME/flutter/bin"

# Verify
flutter doctor
```

### Create Project

```bash
flutter create myapp
cd myapp

# Run
flutter run

# Run on specific device
flutter devices
flutter run -d <device_id>
```

### Common Commands

```bash
flutter doctor          # Check setup
flutter devices         # List devices
flutter run             # Run app
flutter build ios       # Build iOS
flutter build apk       # Build Android
flutter pub get         # Install dependencies
flutter clean           # Clean build
```

---

## iOS Development (Xcode)

### Simulator

```bash
# List simulators
xcrun simctl list devices

# Open Simulator app
open -a Simulator

# Boot specific simulator
xcrun simctl boot "iPhone 15 Pro"

# Install app
xcrun simctl install booted MyApp.app

# Take screenshot
xcrun simctl io booted screenshot screenshot.png
```

### Build Commands

```bash
# Build for simulator
xcodebuild -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 15'

# Archive for release
xcodebuild archive -scheme MyApp -archivePath MyApp.xcarchive
```

---

## Debugging Tools

### React Native

```bash
# Start Metro bundler
npx react-native start

# With cache clear
npx react-native start --reset-cache

# Debug menu (simulator)
# iOS: Cmd+D
# Android: Cmd+M
```

### Flipper (Debug Tool)

```bash
brew install --cask flipper
open -a Flipper
```

Features:
- Network inspector
- Layout inspector
- React DevTools
- Logs

---

## Common Workflows

### React Native Development

```bash
# Terminal 1: Metro
npx react-native start

# Terminal 2: iOS
npx react-native run-ios

# Make changes → Auto reload
# Shake device → Debug menu
```

### Flutter Development

```bash
# Run with hot reload
flutter run

# Press 'r' for hot reload
# Press 'R' for hot restart
# Press 'q' to quit
```

---

## Testing

### React Native

```bash
# Unit tests (Jest)
npm test

# E2E tests (Detox)
npm install -g detox-cli
detox test
```

### Flutter

```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/
```

---

## Build & Release

### iOS (App Store)

1. Archive in Xcode: Product → Archive
2. Distribute App → App Store Connect
3. Submit for review

### Android (Play Store)

```bash
# React Native
cd android && ./gradlew assembleRelease

# Flutter
flutter build appbundle
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Metro bundler stuck | `npx react-native start --reset-cache` |
| Pod install fails | `cd ios && pod install --repo-update` |
| Xcode build fails | Clean build folder: Cmd+Shift+K |
| Simulator slow | Use physical device |
| Android SDK not found | Check ANDROID_HOME env var |
| Flutter doctor issues | Follow each item's fix suggestions |
