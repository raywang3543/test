# AGENTS.md

## Commands

```bash
flutter pub get                  # Install deps
flutter analyze                  # Lint (flutter_lints 5.x)
flutter test                     # Run all tests
flutter test test/widget_test.dart  # Single test file
flutter run                      # Launch app
flutter build apk                # Android release
flutter build ios                # iOS release
flutter pub run flutter_launcher_icons  # Regenerate app icons

cd server && python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000 --reload   # Dev server
```

## Architecture

**Flutter client (Dart 3.7) + FastAPI server (SQLite).** Personality match testing app -- users create surveys, others answer them, AI analyzes compatibility.

State management is plain `StatefulWidget` only. No Provider, GetX, Riverpod, or BLoC.

### Data flow

```
Page → DatabaseHelper (thin facade) → ApiClient (HTTP) → FastAPI → SQLite (emotion_test.db)
```

`DatabaseHelper` uses conditional exports to pick the platform-specific impl (`database_helper_io.dart` / `database_helper_web.dart`), but both delegate entirely to `ApiClient`.

### SharedPreferences keys

- `server_base_url` -- default `http://182.92.61.108`
- `think_mode` -- `"disabled"` (default) or `"enabled"`

### Server tables

`userInfo` (uid PK), `survey` (uid PK), `event` (answererUid + creatorUid).

### AI Service Config

All AI service configs (DeepSeek, Kimi, Xfyun TTS) are now stored **server-side** in `main.py` and fetched by the client via `GET /config`.

Client: `AiConfigService` (`lib/services/ai_config_service.dart`) fetches and caches config from the server. Used by `DeepseekServer`, `KimiService`, and `TtsService`.

Server: Configs are defined in `AI_CONFIG` dict at the top of `main.py` and can be overridden via environment variables:
- `DEEPSEEK_API_KEY`, `DEEPSEEK_BASE_URL`, `DEEPSEEK_MODEL`
- `KIMI_API_KEY`, `KIMI_BASE_URL`, `KIMI_MODEL`
- `XFYUN_APP_ID`, `XFYUN_API_KEY`, `XFYUN_API_SECRET`

### DeepSeek API

`DeepseekServer` calls `https://api.deepseek.com/v1/chat/completions` (OpenAI-compatible) for two purposes:

1. **`generateSurveyQuestions`** -- generates 10 personality-matching questions in JSON format
2. **`analyzePersonalityDetailed`** -- analyzes answerer vs creator answers, returns per-question match % and prose analysis

When the API is unavailable, both methods fall back to a deterministic mock result (`_generateMockResult`).

### Key pages

| Page | Purpose |
|------|---------|
| `HomePage` | Entry; links to create/take tests; server URL + think-mode config |
| `CreateSurveyPage` | Build a survey (AI-generated or manual) |
| `TestListPage` | Browse all surveys from server |
| `AnswerSurveyPage` | Take a survey (single & multi-choice) |
| `UserDetailPage` | View a user's profile and test history |
| `UserProfilePage` | Edit own profile |
| `EventPage` | View all submission events |

## Gotchas

**DeepSeek API errors**: `deepseek_server.dart:11` hardcodes `_apiKey = 'sk-your-deepseek-api-key'` -- replace this with a real key. The model is `deepseek-chat` (line 12). DeepSeek's API is OpenAI-compatible, so no `thinking`/`think` parameters are needed (unlike the old Kimi service). If you get 401, check the API key. If 402, check account balance. To debug any error, print `response.body` before the status code check.

**Server must be running** for any page that queries `/users`, `/surveys`, or `/events`. The default server URL (`http://182.92.61.108`) is a remote host and may not be reachable. For local dev, start the server and change the URL from the HomePage settings dialog (the `dns` icon).

**No CI/CD.** Lint with `flutter analyze`, then test with `flutter test`.
