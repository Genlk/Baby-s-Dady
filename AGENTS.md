# Baby's Dady

A cross-platform mobile app built with **Flutter** (single Dart codebase → Android, iOS and Web). App entry point is `lib/main.dart`; widget tests live in `test/`.

## Cursor Cloud specific instructions

### Toolchain (pre-installed in the VM snapshot; NOT reinstalled by the update script)
- Flutter SDK: `/home/ubuntu/flutter` (stable 3.29.2, Dart 3.7.2)
- Android SDK: `/home/ubuntu/android-sdk` (`ANDROID_HOME` / `ANDROID_SDK_ROOT`)
- JDK 21 (system), used for Gradle/Android builds.
- `PATH` and `ANDROID_HOME`/`ANDROID_SDK_ROOT` are exported from `~/.bashrc`. In a fresh non-login shell run `source ~/.bashrc` (or `export PATH="$PATH:/home/ubuntu/flutter/bin"`) before invoking `flutter`.

### Common commands (run from repo root)
- Lint/analyze: `flutter analyze`
- Test: `flutter test`
- Build Android APK: `flutter build apk --debug` → `build/app/outputs/flutter-apk/app-debug.apk`
- Run on web (for headless demo/dev): `flutter run -d web-server --web-port <port>` then open in Chrome.

### Non-obvious caveats
- **iOS cannot be compiled on this Linux VM.** `flutter build ios` / `ipa` requires macOS + Xcode. The `ios/` Runner project is fully scaffolded and will build on a Mac; on Linux only Android/Web are buildable. This is an Apple platform restriction, not a project bug.
- The first `flutter build apk` triggers a large one-time Gradle + Android NDK/CMake download (several minutes). Subsequent builds are fast. These downloads are cached in the VM snapshot.
- No Android emulator/device is attached in the cloud VM. Use the web target (`-d chrome` / `web-server`) to run and demo the shared UI code; the same widgets compile to Android/iOS.
