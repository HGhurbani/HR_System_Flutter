# HR System - نظام الموارد البشرية

A production-ready bilingual (Arabic/English) internal HR & Recruitment Operations System built with Flutter and Firebase.

---

## Features

### Role-Based Access
| Feature | Admin | Supervisor | Employee |
|---------|-------|------------|----------|
| Manage employees/supervisors | ✅ | ❌ | ❌ |
| Manage candidate CVs | ✅ | ✅ | ❌ |
| Check in / Check out | ✅ | ❌ | ✅ |
| View salary & commission | ✅ | ❌ | ✅ (own only) |
| Approve leave requests | ✅ | ❌ | ❌ |
| Submit leave requests | ❌ | ❌ | ✅ |
| View reports | ✅ | ❌ | ❌ |
| System settings | ✅ | ❌ | ❌ |

### Core Modules
- **Authentication** — Firebase email/password with role-based redirect
- **Candidate/CV Management** — Full CRUD with image upload, filtering by nationality/status, assignment to employees
- **Attendance** — GPS-based check-in/out with geofence validation, shift support, lateness tracking
- **Leaves & Permissions** — Employee submission + admin approval workflow
- **Salary & Commission** — Monthly records per employee
- **Reports & Analytics** — Admin dashboard stats
- **Settings** — Language toggle (AR/EN), dark/light mode, geofence zones

### Technical
- **Flutter** with Material 3, full RTL support
- **Firebase** (Auth, Firestore, Storage, Crashlytics, Analytics, FCM)
- **Clean Architecture** (presentation / application / domain / data layers)
- **Riverpod** state management
- **GoRouter** for declarative navigation with role guards
- **Bilingual** (Arabic default, English available)
- **Dark/Light mode**

---

## Project Structure

```
lib/
├── app.dart                        # MaterialApp.router setup
├── main.dart                       # Entry point, Firebase init
├── firebase_options.dart           # Firebase configuration
├── l10n/
│   ├── app_ar.arb                  # Arabic translations
│   └── app_en.arb                  # English translations
├── core/
│   ├── constants/                  # AppConstants, AppColors
│   ├── errors/                     # AppException
│   ├── extensions/                 # BuildContext extensions
│   ├── router/                     # GoRouter setup with role guards
│   ├── theme/                      # AppTheme (light/dark, Cairo/Inter fonts)
│   ├── utils/
│   └── widgets/                    # Reusable: AppButton, StatCard, EmptyState...
└── features/
    ├── auth/                       # Login, ForgotPassword, Splash
    ├── admin/                      # Admin shell + all admin screens
    ├── supervisor/                 # Supervisor shell + dashboard
    ├── employee/                   # Employee shell + all employee screens
    ├── candidates/                 # Full candidate management module
    ├── attendance/                 # Attendance models, providers, screens
    ├── leaves/                     # Leave requests module
    ├── salary/                     # Salary & commission module
    ├── reports/                    # Reports screen
    └── settings/                   # Language & theme settings
```

---

## Setup Instructions

### 1. Prerequisites
- Flutter SDK >= 3.0.0
- Firebase project with Firestore, Auth, Storage, FCM, Crashlytics enabled
- `flutterfire_cli` installed

### 2. Clone / Open project
```bash
cd d:/HR_SYS_Flutter
```

### 3. Firebase Configuration
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase (generates lib/firebase_options.dart)
flutterfire configure
```

Then add your `google-services.json` (Android) to `android/app/` and `GoogleService-Info.plist` (iOS) to `ios/Runner/`.

### 4. Add Fonts
Download and place these font files in `assets/fonts/`:
- **Cairo**: Regular, Medium, SemiBold, Bold → from [Google Fonts](https://fonts.google.com/specimen/Cairo)
- **Inter**: Regular, Medium, SemiBold, Bold → from [Google Fonts](https://fonts.google.com/specimen/Inter)

### 5. Install Dependencies
```bash
flutter pub get
```

### 6. Generate Code
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 7. Run
```bash
flutter run
```

---

## Firebase Setup

### Firestore Collections
| Collection | Description |
|------------|-------------|
| `users` | All users (admin/supervisor/employee) |
| `candidate_profiles` | Worker candidate CVs |
| `attendance_logs` | Daily check-in/out records |
| `leave_requests` | Employee leave/permission requests |
| `salaries` | Monthly salary records |
| `commissions` | Monthly commission records |
| `company_locations` | Geofence zones |
| `company_settings` | App configuration |
| `notifications` | Push notification records |
| `activity_logs` | Audit trail |

### Deploy Security Rules
```bash
firebase deploy --only firestore:rules
```

The security rules file is at `firestore.rules`.

### Create First Admin User
1. Go to Firebase Console → Authentication → Add user
2. Go to Firestore → Create document in `users` collection with the user's UID:
```json
{
  "uid": "<firebase-auth-uid>",
  "fullName": "System Administrator",
  "email": "admin@company.com",
  "role": "admin",
  "languagePreference": "ar",
  "isActive": true,
  "createdAt": "<timestamp>",
  "updatedAt": "<timestamp>"
}
```

### Sample Seed Data for Testing
Create users in Firebase Auth then add documents to the `users` collection:

**Supervisor:**
```json
{
  "fullName": "Ahmed Al-Rashid",
  "email": "supervisor@company.com",
  "role": "supervisor",
  "languagePreference": "ar",
  "isActive": true
}
```

**Employee:**
```json
{
  "fullName": "Mohammed Al-Sayed",
  "email": "employee@company.com",
  "role": "employee",
  "position": "Sales Executive",
  "employeeCode": "EMP001",
  "languagePreference": "ar",
  "isActive": true
}
```

---

## Android Configuration

### `android/app/build.gradle`
Ensure `minSdkVersion 21` and `multiDexEnabled true`.

### `android/app/src/main/AndroidManifest.xml`
Add permissions:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

---

## iOS Configuration

### `ios/Runner/Info.plist`
Add:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Location is required for attendance check-in</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>Location is required for attendance check-in</string>
```

---

## Architecture Notes

- **Feature-first** folder structure
- **Repository pattern** for data access
- **Provider** pattern (Riverpod) for state
- **GoRouter** with guards prevents unauthorized access
- **Directionality** wrapper in `app.dart` handles RTL/LTR globally
- **SharedPreferences** stores language and theme preferences locally
- Error handling through `AppException` wrapper

---

## Development Phases

- [x] Phase 1: Project setup, Firebase, Auth, Navigation, Theming, Localization
- [x] Phase 2: Admin/Supervisor/Employee module foundations
- [x] Phase 3: Candidate/CV management module
- [x] Phase 4: Attendance, Leaves, Salary modules
- [ ] Phase 5: FCM notifications, advanced reports, polish

---

## License
Internal company use only.
