# HowLong

Track how long it's been. Build streaks. Break habits.

HowLong is a local-first, privacy-focused mobile application built with Flutter that helps you track the time elapsed since an event or track the time elapsed trying to break a habit.

## Features

- **Event Tracking:** Track how long it has been since a specific event occurred.
- **Habit Breaking:** Monitor your progress in breaking habits and building streaks.
- **Privacy First (Local Database):** All your data is stored locally on your device using Isar database.
- **Biometric Authentication:** Secure your data with device-level biometric authentication (FaceID / TouchID / Fingerprint) to ensure only you can view your streaks and habits.
- **Reminders & Notifications:** Get local notifications to keep you on track.
- **Modern UI:** Built with Material Design, `flutter_animate`, and sleek animations.

## Tech Stack

- **Framework:** Flutter
- **State Management:** Riverpod (`flutter_riverpod`)
- **Local Database:** Isar (`isar_community`) & sqflite
- **Authentication:** Local Auth (`local_auth`)
- **Routing:** GoRouter (`go_router`)

## Getting Started

1. **Prerequisites:** Ensure you have the Flutter SDK installed (`>=3.0.0`).
2. **Clone the repository:**
   ```bash
   git clone https://github.com/vikilinho/howlong.git
   ```
3. **Install dependencies:**
   ```bash
   flutter pub get
   ```
4. **Run code generation for Isar:**
   ```bash
   dart run build_runner build -d
   ```
5. **Run the app:**
   ```bash
   flutter run
   ```
