# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Flutter (client)
```bash
flutter pub get          # Install dependencies
flutter analyze          # Run linter
flutter test             # Run all tests
flutter test test/widget_test.dart  # Run a single test file
flutter run              # Run the app
flutter build apk        # Build Android release
flutter build ios        # Build iOS release
```

### Python server
```bash
cd server
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

## Architecture

This is a **client-server** Flutter app (性格匹配测试 / Personality Match Test). Users create personality questionnaires, share them with others to complete, and view AI-analyzed compatibility results.

**State management**: Plain `StatefulWidget` only. No Provider/GetX/Riverpod/BLoC.

### Backend (`server/`)

FastAPI + SQLite (`emotion_test.db`). Three tables: `user_info`, `surveys`, `events`.

- `database.py` — all SQL operations
- `main.py` — REST endpoints for `/users`, `/surveys`, `/events`

### Flutter data layer

All persistence goes through the server via HTTP. The call chain is:

```
Page → DatabaseHelper (thin facade) → ApiClient (HTTP) → FastAPI server
```

`DatabaseHelper` uses conditional exports to select the platform-appropriate implementation (`database_helper_io.dart` / `database_helper_web.dart`), but both delegate entirely to `ApiClient`.

`ServerConfig` stores the base URL in `shared_preferences`. Default: `http://182.92.61.108`. Users can change it from the home screen (the `dns` icon).

### Key models

- `Survey` / `SurveyQuestion` / `SurveyOption` — questionnaire structure; `questionsJson` is stored as a serialized JSON string on the server
- `SurveyQuestion.correctAnswer` — the survey *creator's* answer (single: `int` index; multi: `List<int>`)
- `UserProfile` (in `user_model.dart`) — `basicInfo` (public), `detailedInfo` (revealed only when score ≥ `passingScore`), `passingScore`

### AI analysis

`KimiService` calls the Moonshot (Kimi) API (`moonshot-v1-8k`) after a survey is submitted. It compares the answerer's choices against the creator's `correctAnswer` per question and returns a `PersonalityAnalysisResult` with per-question match percentages, overall score, and four prose fields (creator/player personality + friend/partner compatibility). Falls back to a deterministic mock result when the API is unavailable.

### Pages

| Page | Purpose |
|------|---------|
| `HomePage` | Entry; links to create/take tests; server URL config |
| `CreateSurveyPage` | Build a new questionnaire with scoring |
| `TestListPage` | Browse all surveys on the server |
| `AnswerSurveyPage` | Take a survey (single & multi-choice) |
| `UserListPage` | Browse all users |
| `UserDetailPage` | View a user's profile and test history |
| `UserProfilePage` | Edit own profile |
| `EventPage` | View all submission events |

### Data flow for a survey session

1. Creator fills `CreateSurveyPage`, which POSTs to `/surveys` with `questionsJson` + their UID.
2. Answerer picks a survey from `TestListPage` (GET `/surveys`), completes `AnswerSurveyPage`.
3. On submit: `KimiService.analyzePersonalityDetailed` runs, score is POSTed to `/events`, result shown.
4. `UserDetail`/`EventPage` query `/events` to display history.
