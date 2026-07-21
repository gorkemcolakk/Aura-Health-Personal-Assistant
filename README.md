# Aura Health

Health assistant app built with Flutter.

## AI backend

The app does not ask users for an API key. AI requests go to a backend proxy.

By default the app points at `http://127.0.0.1:8787`, so during local development you only need to start the proxy and run Flutter.

To override the proxy URL, run the app like this:

```powershell
flutter run --dart-define=AURA_AI_PROXY_URL=http://127.0.0.1:8787
```

The app expects the proxy to expose `POST /ai/chat` and return JSON like:

```json
{ "answer": "..." }
```

If the proxy is not available, the app falls back to a local offline response so the UI still works during development.
