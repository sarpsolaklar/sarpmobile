# Sanctuary Health

Sanctuary Health is a Flutter health companion app for medication reminders, hydration tracking, activity logging, profile data, barcode scanning, nearby care lookup, and a health assistant screen.

## Current Status

This project is moving from prototype to MVP. Core local flows exist, and the first production-hardening pass added:

- Firebase Auth backed sign in, registration, password reset, sign out, and splash-session routing.
- Notification service initialization and Android/iOS permission declarations.
- Date-based medication completion logs so "taken today" does not carry into the next day.
- First-pass Firestore writes for medications, medication logs, and profile data under the signed-in user.
- Firestore pull on sign in/dashboard load for medication, medication log, activity, and profile data.
- Basic profile/activity validation and a Privacy & Data screen for local data clearing and account deletion.
- Login widget smoke tests replacing the default Flutter counter test.
- App metadata cleanup for Android and web.

## Requirements

- Flutter SDK matching `environment.sdk` in `pubspec.yaml`.
- Firebase project configured for Android, iOS, macOS, web, and Windows.
- Platform-specific permissions for camera, location, and notifications.

## Setup

1. Install dependencies:

   ```bash
   flutter pub get
   ```

2. Confirm Firebase config files are present:

   - `lib/firebase_options.dart`
   - `android/app/google-services.json`
   - iOS/macOS Firebase files when those platforms are enabled

3. Run the app:

   ```bash
   flutter run
   ```

## Quality Checks

Run these before merging changes:

```bash
flutter analyze
flutter test
```

In this workspace, both commands timed out during the first remediation pass, so the local Flutter/Dart toolchain should be checked before relying on the results.

Latest local check:

- `flutter analyze --no-pub` passes.
- `flutter test test\widget_test.dart --no-pub` fails before running tests because the native asset hook mis-parses the local SDK/project path containing `Yuksek Lisans`.

## Release Notes

Android release signing is intentionally not wired to the debug key. Configure a private release keystore before publishing.

## Remaining High-Priority Work

- Add full two-way Firestore sync and conflict handling per authenticated user.
- Add conflict resolution and cloud delete tombstones for multi-device sync.
- Replace the map placeholder with a real places/maps provider.
- Connect barcode values to a medication data source.
- Add CI for analyze, test, and platform builds.
- Add localization, privacy policy, data deletion, and medical safety copy.
