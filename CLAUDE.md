# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get          # Install dependencies
flutter run              # Run app (debug mode enables Firebase emulators automatically)
flutter test             # Run all tests
flutter test test/viewmodels/login_view_model_test.dart  # Run a single test file
flutter analyze          # Lint
flutter build apk        # Build Android release
flutter build ios        # Build iOS release
```

## Architecture

This is a Flutter app using **MVVM with ChangeNotifier** — no external state management library.

**Layer responsibilities:**
- `lib/models/` — Immutable data classes with `fromMap()`/`toMap()` factories
- `lib/services/` — All Firebase/backend logic (`AuthService`, `AttendanceService`, `EmployeeService`)
- `lib/viewmodels/` — Extend `ChangeNotifier`, own all business logic, call `notifyListeners()` on state changes
- `lib/screens/` — Use `ListenableBuilder` to rebuild on ViewModel changes; no business logic here
- `lib/router/app_router.dart` — GoRouter with auth-based redirect middleware via `_GoRouterRefreshStream`

**Data flow:** Screens observe ViewModels → ViewModels call Services → Services interact with Firebase. Services use Firestore streams for real-time data (streamed into ViewModels via `StreamSubscription`).

## Firebase

- **Project**: `kottra-pos-d7e02`
- **Emulators** are auto-connected in debug mode (see `main.dart`): Auth on `localhost:9099`, Firestore on `localhost:8080`, Functions on `localhost:5001`
- **Only Android and iOS are configured** — other platforms throw `UnsupportedError`
- **Firestore schema**: `stores/{storeId}/hr_employees/{employeeId}` and `stores/{storeId}/hr_attendance/{date}`

## Key conventions

**Employee UID format**: Firebase Auth UIDs for employee accounts follow the pattern `hr_employee:<storeId>:<employeeId>`. `HomeViewModel` parses this to extract store and employee IDs for Firestore queries.

**Auth methods**: Email/password, Google Sign-In, and custom employee token (validated via Cloud Function that returns a Firebase custom token).

**Testing pattern**: Services are faked with simple implementations (e.g., `FakeAuthService`) rather than mocked. Tests live in `test/` mirroring `lib/` structure.

**Routing**: Two routes — `/login` and `/main`. GoRouter redirects unauthenticated users to `/login` and authenticated users away from `/login` to `/main`.
