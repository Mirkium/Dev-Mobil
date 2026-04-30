# Degraded Points (Flutter + Firebase + Material 3)

## Features
- 📸 Capture photos with base64 encoding (no Firebase Storage costs)
- 📍 GPS location with precision and permission prompts
- ✅ Email/password and Google Sign-In authentication
- 📊 Submit reports to Firestore with automatic timestamps
- 📋 View submission history with beautiful Material 3 UI
- 🗺️ View city map (OpenStreetMap) with all reported points
- 🔔 Real-time notifications (success, error, warning, info)

## Firebase Setup (Required)

1. **Create a Firebase project** at https://console.firebase.google.com
2. **Enable authentication methods:**
   - Authentication → Email/Password
   - Authentication → Google
   - Configure your Android/iOS apps for Google Sign-In
3. **Enable Firestore Database:**
   - Create a new Firestore database
   - Start in test mode (or apply security rules from `firebase.rules/firestore.rules`)
4. **Configure apps:**
   - **Android:** Add package name (e.g., `com.example.degraded_points_app`), download `google-services.json` → `android/app/`
   - **iOS:** Add bundle ID (e.g., `com.example.degradedPointsApp`), download `GoogleService-Info.plist` → `ios/Runner/`
5. **Deploy Firestore security rules:**
   - Copy contents of `firebase.rules/firestore.rules` to Firebase Console → Firestore → Rules
   - Replace with contents before deploying

## Image Storage Strategy

**This project uses base64-encoded images in Firestore (no Firebase Storage):**
- Images are encoded to base64 and stored directly in Firestore documents
- Avoids Firebase Storage pay-as-you-go costs
- Suitable for small-to-medium report images
- Estimated max file size per document: ~1 MB (Firestore document limit is 1 MB)
- For larger deployments, migrate to Firebase Storage by using `uploadToStorage()` and storing URLs

**Firestore Report Document Structure:**
```json
{
  "userId": "string",
  "userEmail": "string",
  "images": "base64-encoded-string",
  "location": "GeoPoint {latitude, longitude}",
  "accuracyMeters": "double",
  "title": "string (category)",
  "description": "string",
  "status": "string (e.g., 'new', 'in-progress')",
  "createdAt": "Timestamp"
}
```

## UI/UX Improvements

- **Material 3 Design** with modern gradients and rounded cards
- **Notification System** with colored snackbars (success, error, warning, info)
- **Location Permission Prompts** with settings shortcuts
- **Responsive Layout** for various screen sizes
- **Empty States** with helpful icons and messages

## Google Sign-In Notes

- Android SHA-1/SHA-256 fingerprints must be configured in Firebase Console
- Ensure `android/app/google-services.json` is up-to-date after enabling Google auth
- Google accounts sign in immediately without email verification
- Email/password accounts require email verification before submitting reports

## Run

```bash
flutter pub get
flutter run
```

## Project Structure

```
lib/
├── main.dart                       # App initialization
├── features/
│   ├── auth/
│   │   ├── sign_in_page.dart      # Material 3 login UI
│   │   ├── verify_email_page.dart # Email verification
│   │   └── auth_gate.dart         # Auth state routing
│   ├── report/
│   │   └── create_report_page.dart # Modern report creation
│   ├── history/
│   │   ├── history_page.dart      # Report list with base64 thumbnails
│   │   └── report_detail_page.dart # Beautiful report view
│   ├── home/
│   │   └── home_shell.dart        # Tab navigation
│   └── map/
│       └── map_page.dart          # OpenStreetMap view
├── models/
│   └── report.dart                # Report data model
└── services/
    ├── firebase/
    │   ├── auth_service.dart      # Firebase Auth + Google Sign-In
    │   ├── reports_repo.dart      # Firestore repository
    │   └── firestore_refs.dart    # Firestore providers
    ├── location/
    │   └── location_service.dart  # Geolocator with UI prompts
    └── notification_service.dart  # Snackbar notifications
```

## Firebase Security Rules

Located in `firebase.rules/firestore.rules`. Enforces:
- Only authenticated users with verified emails can create reports
- Users can only read reports (global visibility)
- Users can only update/delete their own reports
- Reports must have base64 image data and 'new' status on creation

# degraded_points_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
