# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get          # Install dependencies
flutter analyze          # Run linter
flutter test             # Run all tests
flutter test test/widget_test.dart  # Run a single test file
flutter run              # Run the app
flutter build apk        # Build Android release
flutter build ios        # Build iOS release
```

## Architecture

This is a Flutter survey app (情感测试 / Emotion Test) that lets users create custom questionnaires, answer them, and view scored results. All data is stored locally via `shared_preferences` — there is no backend.

**State management**: Plain `StatefulWidget` only. No Provider/GetX/Riverpod/BLoC.

**Directory layout:**
```
lib/
├── main.dart                  # App entry + HomePage
├── models/                    # Data classes with toJson/fromJson
│   ├── survey_model.dart      # Survey, SurveyQuestion, SurveyOption
│   └── user_model.dart        # UserProfile
├── pages/                     # Full-screen StatefulWidgets
│   ├── create_survey_page.dart
│   ├── answer_survey_page.dart
│   ├── user_profile_page.dart
│   └── edit_user_page.dart
└── services/                  # SharedPreferences read/write
    ├── survey_storage.dart    # Key: 'saved_survey'
    └── user_storage.dart      # Keys: 'user_uid', user profile fields
```

**Data flow**: Models are serialized to JSON and persisted via service classes. Pages receive data through constructor parameters and navigate with `Navigator.push` + `MaterialPageRoute`. There is one saved survey at a time.

**Key behaviors:**
- `UserProfile.detailedInfo` is only shown when no passing score is set, or when the user's last score meets/exceeds `passingScore`.
- `AnswerSurveyPage` handles both single-choice (radio) and multi-choice (checkbox) questions; each option carries an integer `score`.
- `user_storage.dart` generates a UUID4-style UID via `getOrCreateUid()` and persists it permanently.

**UI**: Material 3 with Chinese-language labels throughout. Gradient AppBars, `AnimatedSwitcher`/`AnimatedContainer` for selection feedback.
