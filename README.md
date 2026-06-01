# Sanctuary Health

Sanctuary Health is a Flutter health companion app built for the mobile programming course project. It includes authentication, medication tracking, daily reminders, hydration tracking, activity logging, profile management, barcode scanning, nearby pharmacy/hospital lookup, and privacy/data controls.

## Features

- Firebase Authentication sign in, registration, password reset, and sign out
- Firestore sync for profile, medications, medication logs, and activity data
- Local data storage with SQLite on mobile/desktop and local storage on web
- Medication reminders with local notifications
- Date-based medication completion tracking
- Google Places nearby pharmacy/hospital search
- Google Static Maps marker preview
- Device location access
- Barcode scanner screen
- Activity and hydration tracking
- Privacy & Data screen for local data clearing and account deletion

## Project Structure

```text
sarpmobile/
  smart_health_app/      Flutter application
  dashboard/             Design prototype
  health_map/            Design prototype
  login_register/        Design prototype
  medications/           Design prototype
  profile/               Design prototype
  splash_screen/         Design prototype
```

## Requirements

- Flutter SDK
- Firebase project
- Google Maps Platform API key
- Enabled Firebase Authentication Email/Password provider
- Enabled Firestore Database
- Enabled Google APIs:
  - Places API or Places API (New)
  - Maps Static API

## Setup

Install packages:

```bash
cd C:\Users\Baris\Desktop\sarpmobile\smart_health_app
flutter pub get
```

Confirm these Firebase files exist:

```text
lib/firebase_options.dart
android/app/google-services.json
```

## Run With Google Maps API Key

The app reads the Google key from `GOOGLE_MAPS_API_KEY`. Do not hard-code the key into source files.

Run on Chrome:

```bash
flutter run -d chrome --dart-define=GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY
```

Run on a connected Android device:

```bash
flutter run -d android --dart-define=GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY
```

Run on Windows:

```bash
flutter run -d windows --dart-define=GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY
```

If the map screen says the API key is missing or the map cannot be loaded, check:

- The app was started with `--dart-define=GOOGLE_MAPS_API_KEY=...`
- Places API / Places API (New) is enabled
- Maps Static API is enabled
- API key restrictions allow the selected APIs
- Web referrers include `http://localhost:*` and `http://127.0.0.1:*`

## Firebase Rules

Use Firestore rules that only allow users to access their own data:

```js
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/data/{document=**} {
      allow read, write: if request.auth != null
                         && request.auth.uid == userId;
    }
  }
}
```

## Quality Checks

Run:

```bash
flutter analyze --no-pub
flutter test test\widget_test.dart --no-pub
```

Latest local verification:

- `flutter analyze --no-pub`: passed
- `flutter test test\widget_test.dart --no-pub`: passed

## GitHub

Repository:

```text
https://github.com/sarpsolaklar/sarpmobile
```

## Notes

- Android release signing is not configured with a private release keystore yet.
- The Google Maps key should be restricted in Google Cloud Console.
- For production, Places API calls should ideally move behind a backend or Firebase Cloud Function.
