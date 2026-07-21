# Aura AI Proxy

Tiny Node proxy that keeps the Gemini API key off the mobile app.

## Run

```powershell
node .\backend\server.mjs
```

Create a `backend/.env` file with:

```env
GEMINI_API_KEY=your_key_here
GEMINI_MODEL=gemini-2.5-flash
PORT=8787
AURA_CORS_ORIGIN=*
```

The Flutter app should be launched with:

```powershell
flutter run --dart-define=AURA_AI_PROXY_URL=http://127.0.0.1:8787
```
