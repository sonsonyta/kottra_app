# Kottra App

A modern Flutter application designed for organizational management, featuring employee attendance tracking, payroll viewing, leave management, and user profiles.

## Architecture

The project follows the **MVVM (Model-View-ViewModel)** architectural pattern to ensure separation of concerns, testability, and maintainability:

*   **Models (`lib/models/`)**: Defines the data structures and domain objects.
*   **Views (`lib/screens/`)**: Contains the UI layers, broken down into tabs (Home, Attendance, Payroll, Profile) and separate screens (Login, Leave).
*   **ViewModels (`lib/viewmodels/`)**: Contains the business logic and state management for the views.
*   **Services (`lib/services/`)**: Handles external integrations, API calls, and interactions with Firebase.
*   **Controllers (`lib/theme/`, `lib/config/`)**: Singleton controllers (like `ThemeController`, `LocaleController`) integrated with `ListenableBuilder` for app-wide reactive state changes.

## Core Technologies & Libraries

*   **Framework**: Flutter (SDK ^3.11.4)
*   **Routing**: [`go_router`](https://pub.dev/packages/go_router) for declarative and deep-linkable routing.
*   **Backend as a Service (BaaS)**: Firebase
    *   `firebase_auth` & `google_sign_in`: For user authentication.
    *   `cloud_firestore`: For NoSQL cloud database.
    *   `firebase_storage`: For file and media storage.
    *   `cloud_functions`: For serverless backend logic.
    *   `firebase_app_check`: For abuse protection.
*   **State Management**: Native Flutter `ListenableBuilder` combined with `ChangeNotifier` and singletons.
*   **Localization**: `flutter_localizations` & `intl`. Custom localization system supporting English and Khmer languages.
*   **Hardware / Device**:
    *   `geolocator`: For fetching user location (used in Attendance tracking).
    *   `file_picker`: For selecting files from the device.
*   **Local Storage**: `shared_preferences` for storing lightweight, persistent user settings (like theme and language choices).

## Features

*   **Authentication**: Secure login using Firebase Authentication (Email/Password & Google Sign-In).
*   **Attendance Tracking**: Location-aware check-in/check-out functionality.
    *   **Continuous Shifts**: Supports overnight shifts natively without splitting records across days.
    *   **10-Hour Gap Rule**: Users can begin a new shift (check-in again) only after a 10-hour rest period since their last check-out. 
    *   **Leave & Absent Guard**: Check-ins are locked for the remainder of the day if a user is marked as "Absent" or "On Leave".
*   **Leave Management**: Request and manage employee leaves (Under development).
*   **Payroll**: View salary and payroll history (Under development).
*   **Internationalization**: Full support for English and Khmer (Cambodian) languages.
*   **Theming**: Support for Light and Dark modes.

## Getting Started

### Prerequisites

*   Flutter SDK (^3.11.4)
*   Firebase CLI (if you wish to run emulators or deploy functions)

### Running Locally

This project supports the Firebase Emulator Suite for local development.

1.  **Clone the repository:**
    ```bash
    git clone <repository_url>
    cd kottra_app
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the application (Debug mode automatically uses Firebase Emulators):**
    ```bash
    flutter run
    ```

> **Note**: When running in `kDebugMode`, the app is configured in `main.dart` to automatically connect to local Firebase emulators (Auth, Firestore, Functions, Storage). Ensure your emulators are running or adjust the environment configuration as needed.
