import http from 'node:http';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function loadEnvFile(filePath) {
  try {
    const source = await readFile(filePath, 'utf8');
    for (const rawLine of source.split(/\r?\n/)) {
      const line = rawLine.trim();
      if (!line || line.startsWith('#')) {
        continue;
      }

      const equalsIndex = line.indexOf('=');
      if (equalsIndex <= 0) {
        continue;
      }

      const key = line.slice(0, equalsIndex).trim();
      let value = line.slice(equalsIndex + 1).trim();

      if (
        (value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))
      ) {
        value = value.slice(1, -1);
      }

      if (!(key in process.env)) {
        process.env[key] = value;
      }
    }
  } catch (error) {
    if (error?.code !== 'ENOENT') {
      throw error;
    }
  }
}

await loadEnvFile(path.join(__dirname, '.env'));
await loadEnvFile(path.join(__dirname, '.env.local'));

const PORT = Number(process.env.PORT || 8787);
const GEMINI_API_KEY = process.env.GEMINI_API_KEY || '';
const GEMINI_MODEL = process.env.GEMINI_MODEL || 'gemini-2.5-flash';
const ALLOW_ORIGIN = process.env.AURA_CORS_ORIGIN || '*';

function json(response, statusCode, body, extraHeaders = {}) {
  const payload = JSON.stringify(body);
  response.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': ALLOW_ORIGIN,
    'Access-Control-Allow-Methods': 'POST, OPTIONS, GET',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Cache-Control': 'no-store',
    ...extraHeaders,
  });
  response.end(payload);
}

function textFromCandidate(data) {
  const candidates = Array.isArray(data?.candidates) ? data.candidates : [];
  const parts = [];

  for (const candidate of candidates) {
    const content = candidate?.content;
    const contentParts = Array.isArray(content?.parts) ? content.parts : [];
    for (const part of contentParts) {
      if (typeof part?.text === 'string' && part.text.trim()) {
        parts.push(part.text.trim());
      }
    }
  }

  return parts.join('\n').trim();
}

async function readJsonBody(request) {
  const chunks = [];
  for await (const chunk of request) {
    chunks.push(typeof chunk === 'string' ? Buffer.from(chunk) : chunk);
  }

  if (chunks.length === 0) {
    return null;
  }

  const raw = Buffer.concat(chunks).toString('utf8');
  return JSON.parse(raw);
}

function buildSystemInstruction() {
  return {
    parts: [
      {
        text:
          'Sen Aura Health icin Turkce konusan, temkinli bir saglik asistanisin. Tani koyma, acil durumlarda doktora yonlendir, kisisel veriyi kisaca kullan ve net uygulanabilir oneriler ver.',
      },
    ],
  };
}

function buildPrompt(profile, question) {
  const bmi = Number(profile?.bmi || 0);
  const waterTargetMl = Number(profile?.waterTargetMl || 0);
  return [
    'Kullanici profili:',
    `- Ad: ${profile?.name || 'Bilinmiyor'}`,
    `- Yas: ${profile?.age ?? 'Bilinmiyor'}`,
    `- Boy: ${profile?.heightCm ?? 'Bilinmiyor'} cm`,
    `- Kilo: ${profile?.weightKg ?? 'Bilinmiyor'} kg`,
    `- VKI: ${bmi ? bmi.toFixed(1) : 'Bilinmiyor'}`,
    `- Aktivite: ${profile?.activity || 'Bilinmiyor'}`,
    `- Gunluk su hedefi: ${waterTargetMl ? `${waterTargetMl} ml` : 'Bilinmiyor'}`,
    `- Hedef: ${profile?.healthGoal || 'Bilinmiyor'}`,
    `- Notlar: ${profile?.conditions || 'Yok'}`,
    '',
    `Soru: ${question}`,
  ].join('\n');
}

async function handleChat(request, response) {
  if (!GEMINI_API_KEY) {
    return json(response, 500, {
      error:
        'GEMINI_API_KEY tanimli degil. Backend ortam degiskenine Gemini anahtari eklenmeli.',
    });
  }

  let payload;
  try {
    payload = await readJsonBody(request);
  } catch {
    return json(response, 400, {
      error: 'Gecersiz JSON payload.',
    });
  }

  const question = String(payload?.question || '').trim();
  const profile = payload?.profile || {};
  if (!question) {
    return json(response, 400, {
      error: 'question alanı zorunlu.',
    });
  }

  const geminiResponse = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(GEMINI_MODEL)}:generateContent`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': GEMINI_API_KEY,
      },
      body: JSON.stringify({
        systemInstruction: buildSystemInstruction(),
        contents: [
          {
            role: 'user',
            parts: [
              {
                text: buildPrompt(profile, question),
              },
            ],
          },
        ],
      }),
    },
  );

  const raw = await geminiResponse.text();
  let data = null;
  try {
    data = raw ? JSON.parse(raw) : null;
  } catch {
    data = null;
  }

  if (!geminiResponse.ok) {
    return json(response, geminiResponse.status, {
      error: 'Gemini isteği başarısız oldu.',
      details: data?.error?.message || raw || 'Bilinmeyen hata',
    });
  }

  const answer = textFromCandidate(data);
  if (!answer) {
    return json(response, 502, {
      error: 'Gemini yanıtı okunamadı.',
      raw: data,
    });
  }

  return json(response, 200, { answer });
}

const server = http.createServer(async (request, response) => {
  if (request.method === 'OPTIONS') {
    response.writeHead(204, {
      'Access-Control-Allow-Origin': ALLOW_ORIGIN,
      'Access-Control-Allow-Methods': 'POST, OPTIONS, GET',
      'Access-Control-Allow-Headers': 'Content-Type',
      'Cache-Control': 'no-store',
    });
    response.end();
    return;
  }

  const url = new URL(request.url || '/', `http://${request.headers.host || 'localhost'}`);

  if (request.method === 'GET' && url.pathname === '/health') {
    return json(response, 200, {
      ok: true,
      model: GEMINI_MODEL,
    });
  }

  if (request.method === 'POST' && url.pathname === '/ai/chat') {
    return handleChat(request, response);
  }

  return json(response, 404, {
    error: 'Not found',
  });
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(`Aura AI proxy running on http://127.0.0.1:${PORT}`);
  console.log(`Using Gemini model: ${GEMINI_MODEL}`);
});
