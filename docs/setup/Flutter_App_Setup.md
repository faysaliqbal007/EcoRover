# Flutter Mobile Application Setup

## System Requirements
- Flutter SDK: `3.47.5` or later
- Dart SDK: `3.3.0` or later
- Android Studio / VS Code with Flutter extensions
- Android Target: Android 7.0+ (API level 24 to 34)

## Installation & Build Commands
1. Navigate to the app directory:
   ```bash
   cd flutter-app
   ```
2. Retrieve all dependencies:
   ```bash
   flutter pub get
   ```
3. Run the automated unit test suite (44 unit tests):
   ```bash
   flutter test
   ```
4. Build the release APK:
   ```bash
   flutter build apk --release
   ```
   The generated APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

5. Run directly on an Android device via USB:
   ```bash
   flutter run
   ```

## Connecting to the Rover
1. Turn on the EcoRover chassis switch.
2. On your Android phone, go to **Wi-Fi Settings** and connect to:
   - **SSID**: `EcoRover`
   - **Password**: `12345678`
   *(If Android prompts "This network has no internet access. Stay connected?", tap **Yes / Always stay connected**).*
3. Launch the **EcoRover** app. Telemetry indicators will illuminate green and the live camera stream will begin streaming immediately.
