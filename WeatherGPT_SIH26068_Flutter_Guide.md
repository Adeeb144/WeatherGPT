# WeatherGPT: SIH 2026 (PS 26068) Build Guide (Flutter)

A step-by-step plan to build WeatherGPT as a Flutter mobile app with a free-tier backend, scoped for a 36-hour hackathon.

---

## 1. Problem Statement (Official)

| Field | Details |
|---|---|
| **Problem Statement ID** | 26068 |
| **Title** | WeatherGPT: Conversational AI for Weather Forecasting, Alerts, and Climate Information |
| **Organization** | Ministry of Earth Sciences (MoES) |
| **Department** | India Meteorological Department |
| **Category** | Software |
| **Theme** | Disaster Management |

### Background
Weather information is often distributed through multiple portals, bulletins, satellite products, and forecast systems, making it difficult for common users, researchers, disaster managers, and government agencies to quickly obtain actionable insights.

There is a need for an intelligent conversational platform that can provide real-time weather information, forecasts, warnings, climate analysis, and decision support in natural language.

### Objective
Develop an AI-powered chatbot platform named **WeatherGPT** that integrates meteorological datasets, forecasting models, and disaster warning systems to provide accurate, contextual, and multilingual weather intelligence through conversational interfaces.

### Key Features
1. Real-time weather information retrieval
2. Natural language querying for weather forecasts
3. Integration with numerical weather prediction (NWP) models such as GFS/WRF
4. Extreme weather alerts and early warning dissemination
5. Location-based forecasting and advisory generation
6. Multilingual support for Indian languages
7. Climate trend and historical weather analysis
8. Voice-enabled interaction for rural accessibility

### Expected Solution
- A mobile-based conversational AI platform
- Backend integration with meteorological databases, websites and APIs
- AI/LLM-based query understanding engine
- Scalable architecture supporting real-time data ingestion

### Suggested Technology Stack
- Python / FastAPI / Node.js
- MQTT / WIS2.0 / WebSocket
- LLMs (OpenAI, Llama, Gemini, etc.)
- GIS tools and weather APIs
- PostgreSQL / MongoDB
- Docker / Kubernetes

### Expected Outcomes
- Faster dissemination of weather information
- Improved public accessibility to forecasts
- Better disaster preparedness and response
- Intelligent weather decision-support system for agriculture, aviation, marine, and urban planning

### Possible Use Cases
- Farmers seeking crop-weather advisories
- Aviation weather briefing
- Flood/cyclone warning dissemination
- Smart city weather monitoring
- Climate analytics for researchers

### Evaluation Parameters
- Accuracy and relevance
- Response latency
- Multilingual capability
- User interface and accessibility
- Scalability and innovation
- Integration with real-time meteorological systems
- Voice-enabled interaction for rural accessibility

---

## 2. Our Approach

**Core idea:** an LLM **tool-calling agent** (not RAG). The user asks a question in natural language (text or voice, in English/Hindi/Telugu). The LLM figures out the intent, calls weather tools (forecast, alerts, climate history), and turns the raw data into a short, actionable answer in the user's language.

### MVP scope (build this)

| Feature | How we deliver it |
|---|---|
| Real-time weather | Open-Meteo API |
| Natural language queries | Gemini function calling |
| Location-based forecast | Geocoding API + GPS from Flutter |
| Alerts | Rule-based severe-weather detection on forecast data + IMD warning source (see Step 5) |
| Multilingual | English, Hindi, Telugu via Gemini |
| Climate/historical trends | Open-Meteo Historical API |
| Voice | `speech_to_text` + `flutter_tts` (on-device, free) |
| Advisory generation | LLM turns data into farmer/traveller advice |

### Future work (mention in pitch, do not build)
- Direct GFS/WRF model ingestion (we consume model-derived forecasts via API instead)
- MQTT / WIS 2.0 real-time feeds
- Kubernetes, PostgreSQL at scale
- Full support for all 22 scheduled languages
- Push notifications via FCM for alert dissemination

---

## 3. Architecture

```
┌──────────────────────────┐
│   Flutter App (Android)  │
│  Chat UI · Voice · GPS   │
│  Language picker · Alerts│
└────────────┬─────────────┘
             │ HTTPS (JSON)
┌────────────▼─────────────┐
│     FastAPI Backend      │
│  /chat  /alerts  /health │
│                          │
│  ┌────────────────────┐  │
│  │ Gemini Agent       │  │
│  │ (function calling) │  │
│  └───┬────┬────┬──────┘  │
│      │    │    │         │
│  get_forecast │ get_climate_trend
│      │  get_alerts       │
└──────┼────┼────┼─────────┘
       │    │    │
 ┌─────▼────▼────▼─────────┐
 │ Open-Meteo (forecast,   │
 │ geocoding, archive)     │
 │ IMD warnings / RSS      │
 └─────────────────────────┘
```

**Why a backend at all?** Never put the Gemini API key inside the Flutter app. Anyone can extract it from the APK. The backend holds the key and does the tool-calling.

---

## 4. Tech Stack (all free tier)

| Layer | Choice | Cost |
|---|---|---|
| Mobile app | Flutter (Dart) | Free |
| State management | Provider or Riverpod | Free |
| Backend | Python + FastAPI | Free |
| LLM | Gemini API (free tier via Google AI Studio) | Free within limits |
| Weather data | Open-Meteo (forecast, geocoding, archive) | Free, no key |
| Voice input | `speech_to_text` package | Free |
| Voice output | `flutter_tts` package | Free |
| Location | `geolocator` package | Free |
| HTTP | `http` or `dio` package | Free |
| Backend hosting | Render / Railway free tier, or local + ngrok for demo | Free |

> Free-tier limits and model names change. Check Google AI Studio for the current free Gemini Flash model and its rate limits before you start.

---

## 5. 36-Hour Timeline

| Hours | Goal |
|---|---|
| 0–2 | Setup, repo, accounts, API keys, test Open-Meteo in browser |
| 2–8 | Backend: weather tools + Gemini agent working via `curl`/Postman |
| 8–12 | Alerts logic + climate trend tool |
| 12–22 | Flutter: chat UI, connect to backend, location |
| 22–28 | Multilingual + voice input/output |
| 28–32 | Alerts screen, polish UI, error handling |
| 32–35 | Deploy backend, build APK, test on a real phone |
| 35–36 | Demo script, slides, screen recording backup |

---

## 6. Step-by-Step Development

### Step 0: Setup (Hours 0–2)

**Accounts and keys**
1. Create a Gemini API key at Google AI Studio.
2. Create a GitHub repo `weathergpt` with two folders: `backend/` and `app/`.
3. Install: Flutter SDK, Android Studio (emulator), Python 3.11+, VS Code.

**Verify Flutter works**
```bash
flutter doctor
flutter create app
cd app && flutter run
```

**Test the weather API in your browser** (no key needed):
```
https://geocoding-api.open-meteo.com/v1/search?name=Warangal&count=1

https://api.open-meteo.com/v1/forecast?latitude=17.97&longitude=79.6&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max&current=temperature_2m,relative_humidity_2m,wind_speed_10m,precipitation&timezone=Asia/Kolkata
```

---

### Step 1: Backend skeleton (Hours 2–3)

```bash
cd backend
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install fastapi uvicorn httpx python-dotenv google-genai
```

Create `backend/.env`:
```
GEMINI_API_KEY=your_key_here
```

Create `backend/main.py`:
```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="WeatherGPT API")
app.add_middleware(CORSMiddleware, allow_origins=["*"],
                   allow_methods=["*"], allow_headers=["*"])

@app.get("/health")
def health():
    return {"status": "ok"}
```

Run it:
```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

---

### Step 2: Weather tools (Hours 3–6)

Create `backend/tools.py`. These are plain Python functions the LLM will call.

```python
import httpx

GEO_URL = "https://geocoding-api.open-meteo.com/v1/search"
FORECAST_URL = "https://api.open-meteo.com/v1/forecast"
ARCHIVE_URL = "https://archive-api.open-meteo.com/v1/archive"


def _geocode(location: str):
    r = httpx.get(GEO_URL, params={"name": location, "count": 1, "country_code": "IN"}, timeout=10)
    r.raise_for_status()
    results = r.json().get("results")
    if not results:
        return None
    top = results[0]
    return {"name": top["name"], "state": top.get("admin1", ""),
            "lat": top["latitude"], "lon": top["longitude"]}


def get_forecast(location: str, days: int = 3) -> dict:
    """Get current weather and daily forecast for an Indian location.

    Args:
        location: City, town or village name, e.g. "Warangal".
        days: Number of forecast days (1 to 7).
    """
    place = _geocode(location)
    if not place:
        return {"error": f"Could not find location '{location}'"}
    params = {
        "latitude": place["lat"], "longitude": place["lon"],
        "current": "temperature_2m,relative_humidity_2m,wind_speed_10m,precipitation",
        "daily": "temperature_2m_max,temperature_2m_min,precipitation_sum,"
                 "precipitation_probability_max,wind_speed_10m_max",
        "forecast_days": max(1, min(days, 7)),
        "timezone": "Asia/Kolkata",
    }
    r = httpx.get(FORECAST_URL, params=params, timeout=15)
    r.raise_for_status()
    return {"place": place, "data": r.json()}


def get_climate_trend(location: str, start_date: str, end_date: str) -> dict:
    """Get historical daily weather for a location to analyse climate trends.

    Args:
        location: City or town name.
        start_date: Start date in YYYY-MM-DD format.
        end_date: End date in YYYY-MM-DD format.
    """
    place = _geocode(location)
    if not place:
        return {"error": f"Could not find location '{location}'"}
    params = {
        "latitude": place["lat"], "longitude": place["lon"],
        "start_date": start_date, "end_date": end_date,
        "daily": "temperature_2m_mean,precipitation_sum",
        "timezone": "Asia/Kolkata",
    }
    r = httpx.get(ARCHIVE_URL, params=params, timeout=20)
    r.raise_for_status()
    d = r.json()["daily"]
    temps = [t for t in d["temperature_2m_mean"] if t is not None]
    rain = [p for p in d["precipitation_sum"] if p is not None]
    return {
        "place": place,
        "avg_temp_c": round(sum(temps) / len(temps), 1) if temps else None,
        "total_rain_mm": round(sum(rain), 1),
        "days": len(d["time"]),
    }
```

Test each function in a Python shell before moving on.

---

### Step 3: Alerts logic (Hours 6–10)

Two layers, and be honest about which is which in your pitch.

**Layer A: Rule-based alerts from forecast data (build this, it works reliably).**
Add to `tools.py`:

```python
def get_alerts(location: str) -> dict:
    """Check the next 3 days for extreme weather at a location.

    Args:
        location: City or town name.
    """
    res = get_forecast(location, days=3)
    if "error" in res:
        return res
    daily = res["data"]["daily"]
    alerts = []
    for i, day in enumerate(daily["time"]):
        tmax = daily["temperature_2m_max"][i]
        rain = daily["precipitation_sum"][i]
        wind = daily["wind_speed_10m_max"][i]
        if tmax is not None and tmax >= 45:
            alerts.append({"date": day, "type": "Severe heatwave", "severity": "red",
                           "detail": f"Max temp {tmax}°C"})
        elif tmax is not None and tmax >= 40:
            alerts.append({"date": day, "type": "Heatwave", "severity": "orange",
                           "detail": f"Max temp {tmax}°C"})
        if rain is not None and rain >= 115:
            alerts.append({"date": day, "type": "Very heavy rain", "severity": "red",
                           "detail": f"{rain} mm expected"})
        elif rain is not None and rain >= 65:
            alerts.append({"date": day, "type": "Heavy rain", "severity": "orange",
                           "detail": f"{rain} mm expected"})
        if wind is not None and wind >= 60:
            alerts.append({"date": day, "type": "Strong winds", "severity": "orange",
                           "detail": f"Up to {wind} km/h"})
    return {"place": res["place"], "alerts": alerts,
            "note": "Computed from forecast data. Always follow official IMD warnings."}
```

> The thresholds above are illustrative. Check IMD's own rainfall and heatwave category definitions and adjust them before you present.

**Layer B: Official IMD warnings (add if time permits).**
IMD publishes warnings on its website (mausam.imd.gov.in) and in bulletins. There is no guaranteed clean public JSON API, so:
1. Open IMD's warning pages and look for RSS/XML feeds or structured pages you can parse.
2. If you find a stable feed, poll it every 15–30 minutes and cache the result.
3. If not, say so in the pitch: "In production, this connects to IMD's warning feed (CAP/WIS 2.0). For the prototype we compute alerts from forecast data."

Judges respect an honest, well-explained limitation far more than a fake integration.

---

### Step 4: Gemini agent with function calling (Hours 8–12)

Create `backend/agent.py`:

```python
import os
from dotenv import load_dotenv
from google import genai
from google.genai import types
from tools import get_forecast, get_alerts, get_climate_trend

load_dotenv()
client = genai.Client(api_key=os.environ["GEMINI_API_KEY"])

MODEL = "gemini-2.5-flash"  # confirm the current free model name in AI Studio

SYSTEM_PROMPT = """You are WeatherGPT, a helpful weather assistant for India.

Rules:
- Always call a tool to get real data. Never invent weather numbers.
- Reply in the same language the user writes in (English, Hindi, or Telugu),
  unless a target language is specified.
- Keep answers short, clear, and practical (3 to 5 sentences).
- Give an actionable recommendation when the user asks what to do
  (e.g. spraying crops, travel, carrying an umbrella).
- If severe weather is expected, put the warning first.
- Use metric units (°C, mm, km/h).
- If a location is not found, ask the user to clarify.
- Today's date is {today}.
"""

def run_agent(message: str, history: list[dict], language: str = "auto") -> str:
    from datetime import date
    system = SYSTEM_PROMPT.format(today=date.today().isoformat())
    if language != "auto":
        system += f"\nAlways answer in {language}."

    contents = []
    for turn in history[-10:]:  # keep the last 10 turns for context
        contents.append(types.Content(
            role=turn["role"], parts=[types.Part(text=turn["text"])]))
    contents.append(types.Content(role="user", parts=[types.Part(text=message)]))

    response = client.models.generate_content(
        model=MODEL,
        contents=contents,
        config=types.GenerateContentConfig(
            system_instruction=system,
            tools=[get_forecast, get_alerts, get_climate_trend],  # automatic function calling
            temperature=0.3,
        ),
    )
    return response.text
```

Add the chat endpoint to `main.py`:

```python
from pydantic import BaseModel
from agent import run_agent

class ChatRequest(BaseModel):
    message: str
    history: list[dict] = []
    language: str = "auto"

@app.post("/chat")
def chat(req: ChatRequest):
    try:
        reply = run_agent(req.message, req.history, req.language)
        return {"reply": reply}
    except Exception as e:
        return {"reply": "Sorry, I could not fetch the weather right now. Please try again.",
                "error": str(e)}
```

**Test with curl before building any UI:**
```bash
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Will it rain in Warangal tomorrow?"}'
```

Test these tricky queries:
- "Will it rain in Warangal the day after tomorrow?"
- "వరంగల్‌లో రేపు వర్షం పడుతుందా?" (Telugu)
- "क्या कल हैदराबाद में बारिश होगी?" (Hindi)
- "Is it safe to spray pesticide in Nizamabad tomorrow?"
- "How was rainfall in Pune in July last year compared to this year?"
- "asdfgh" (nonsense input, should not crash)

**Note:** the SDK's automatic function calling details can change between versions. If a call fails, check the current `google-genai` docs for function calling.

---

### Step 5: Flutter app setup (Hours 12–14)

Add packages in `app/pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
  provider: ^6.1.0
  geolocator: ^12.0.0
  speech_to_text: ^7.0.0
  flutter_tts: ^4.0.0
  shared_preferences: ^2.2.0
```

Run `flutter pub get`. (Version numbers move fast; if pub complains, run `flutter pub add <package>` to get the latest.)

**Android permissions**, in `android/app/src/main/AndroidManifest.xml`, before `<application>`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

**Suggested folder structure**
```
app/lib/
├── main.dart
├── models/
│   └── message.dart
├── services/
│   ├── api_service.dart
│   ├── voice_service.dart
│   └── location_service.dart
├── providers/
│   └── chat_provider.dart
└── screens/
    ├── chat_screen.dart
    └── alerts_screen.dart
```

---

### Step 6: Chat UI and backend connection (Hours 14–22)

**`models/message.dart`**
```dart
class Message {
  final String text;
  final bool isUser;
  Message({required this.text, required this.isUser});
}
```

**`services/api_service.dart`**
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';

class ApiService {
  // Android emulator: 10.0.2.2 reaches your PC's localhost.
  // Real phone: use your PC's LAN IP, or the deployed URL / ngrok URL.
  static const String baseUrl = 'http://10.0.2.2:8000';

  Future<String> sendMessage(String text, List<Message> history, String language) async {
    final body = jsonEncode({
      'message': text,
      'language': language,
      'history': history
          .map((m) => {'role': m.isUser ? 'user' : 'model', 'text': m.text})
          .toList(),
    });
    final res = await http
        .post(Uri.parse('$baseUrl/chat'),
            headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) throw Exception('Server error ${res.statusCode}');
    return jsonDecode(utf8.decode(res.bodyBytes))['reply'] as String;
  }
}
```

> Use `utf8.decode(res.bodyBytes)` or Hindi/Telugu text will show as garbage.

**`providers/chat_provider.dart`**
```dart
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../services/api_service.dart';

class ChatProvider extends ChangeNotifier {
  final _api = ApiService();
  final List<Message> messages = [];
  bool loading = false;
  String language = 'auto'; // 'auto', 'English', 'Hindi', 'Telugu'

  void setLanguage(String lang) {
    language = lang;
    notifyListeners();
  }

  Future<String?> send(String text) async {
    if (text.trim().isEmpty) return null;
    final history = List<Message>.from(messages);
    messages.add(Message(text: text, isUser: true));
    loading = true;
    notifyListeners();
    try {
      final reply = await _api.sendMessage(text, history, language);
      messages.add(Message(text: reply, isUser: false));
      return reply;
    } catch (e) {
      const err = 'Could not reach WeatherGPT. Check your connection and try again.';
      messages.add(Message(text: err, isUser: false));
      return null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
```

**`screens/chat_screen.dart`** should contain:
- `ListView.builder` of message bubbles (user right-aligned, bot left-aligned)
- A typing indicator while `loading` is true
- A text field, send button, and mic button (wired in Step 8)
- Language dropdown in the app bar
- 3–4 suggestion chips on an empty state: "Weather today", "Will it rain tomorrow?", "Any alerts near me?", "Crop advice"

**`main.dart`**
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/chat_provider.dart';
import 'screens/chat_screen.dart';

void main() => runApp(
  ChangeNotifierProvider(create: (_) => ChatProvider(), child: const WeatherGptApp()),
);

class WeatherGptApp extends StatelessWidget {
  const WeatherGptApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'WeatherGPT',
    theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
    home: const ChatScreen(),
  );
}
```

---

### Step 7: Location awareness (Hours 20–22)

Use GPS so users can ask "weather near me" without typing a city.

**`services/location_service.dart`**
```dart
import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position?> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) return null;
    return Geolocator.getCurrentPosition();
  }
}
```

**How to use it:** when the message contains "near me" or "my location", send `lat`/`lon` with the request. On the backend, add the coordinates to the system prompt ("User's current coordinates: lat, lon") and add an optional `lat`/`lon` path in `get_forecast`. Simplest approach: add a `get_forecast_by_coords(lat, lon)` tool.

---

### Step 8: Voice input and output (Hours 22–28)

**`services/voice_service.dart`**
```dart
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  final _stt = SpeechToText();
  final _tts = FlutterTts();
  bool _ready = false;

  // Locale IDs: English 'en_IN', Hindi 'hi_IN', Telugu 'te_IN'
  static const localeMap = {
    'English': 'en_IN', 'Hindi': 'hi_IN', 'Telugu': 'te_IN', 'auto': 'en_IN',
  };

  Future<bool> init() async => _ready = await _stt.initialize();

  Future<void> listen(String language, void Function(String) onResult) async {
    if (!_ready) await init();
    await _stt.listen(
      localeId: localeMap[language] ?? 'en_IN',
      onResult: (r) { if (r.finalResult) onResult(r.recognizedWords); },
    );
  }

  Future<void> stopListening() => _stt.stop();

  Future<void> speak(String text, String language) async {
    await _tts.setLanguage(localeMap[language]?.replaceAll('_', '-') ?? 'en-IN');
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() => _tts.stop();
}
```

**Wire it up**
1. Mic button: press → `listen(...)` → on final result, call `chatProvider.send(text)`.
2. After each bot reply, if the user used voice, call `speak(reply, language)`.
3. Add a speaker icon on each bot bubble to replay it.

**Reality check:** Hindi and Telugu speech recognition and TTS depend on the phone's installed language packs (Google's speech services). Test on a real Android device and download the offline language packs for Hindi/Telugu in the phone settings. If Telugu voice is unreliable, keep it as a bonus and lead the demo with English/Hindi voice.

---

### Step 9: Alerts screen (Hours 28–31)

1. Add `GET /alerts?location=Warangal` to FastAPI that calls `get_alerts()` and returns JSON.
2. In Flutter, build `alerts_screen.dart` with cards colour-coded by severity (red, orange, yellow).
3. Add a bottom navigation bar: **Chat | Alerts**.
4. Auto-show a red banner at the top of the chat if the user's current location has a red or orange alert.
5. Optional: a "Share alert" button using the `share_plus` package to demonstrate dissemination.

---

### Step 10: Climate trends (Hours 28–31, parallel)

The `get_climate_trend` tool already works through chat. To stand out, add a small chart:
- Use the `fl_chart` package to plot monthly average temperature or rainfall for the last 12 months.
- Trigger it from a chip like "Show climate trend for my city".
- Backend: add a `/climate?location=...` endpoint returning monthly aggregates.

---

### Step 11: Polish (Hours 28–33)

- [ ] App name, icon, and splash screen (`flutter_launcher_icons`)
- [ ] Loading skeleton or typing dots while waiting
- [ ] Friendly error messages (no internet, server down, location not found)
- [ ] Response time under about 5 seconds (keep prompts short, cap history at 10 turns)
- [ ] Large tap targets and readable fonts for rural, low-literacy users
- [ ] Cache the last successful answer so the app shows something offline
- [ ] Disclaimer in settings: "Alerts are computed from forecast data. Follow official IMD warnings."

---

### Step 12: Deploy (Hours 32–35)

**Backend on Render (free tier)**
1. Add `backend/requirements.txt`:
   ```
   fastapi
   uvicorn
   httpx
   python-dotenv
   google-genai
   ```
2. Push to GitHub, create a new Render Web Service pointing at `backend/`.
3. Build command: `pip install -r requirements.txt`
4. Start command: `uvicorn main:app --host 0.0.0.0 --port $PORT`
5. Add `GEMINI_API_KEY` in Render's environment settings (never commit `.env`; add it to `.gitignore`).
6. Free instances sleep when idle, so hit `/health` a minute before your demo to wake it up.

**Fallback if deployment fails:** run the backend on your laptop and expose it with `ngrok http 8000`. Put the ngrok URL in `api_service.dart`.

**Build the APK**
```bash
cd app
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

Update `baseUrl` to the deployed URL before building. For HTTP (non-HTTPS) URLs during testing you may need `android:usesCleartextTraffic="true"` in the manifest, but prefer HTTPS.

---

### Step 13: Testing checklist (Hours 33–35)

| Test | Expected |
|---|---|
| "Weather in Hyderabad" | Current temp + short summary |
| "Will it rain tomorrow in Warangal?" | Uses forecast, gives yes/no with % |
| Telugu and Hindi queries | Reply in the same language |
| "Any alerts near me?" | Uses GPS, lists alerts or says none |
| Farmer advice query | Actionable recommendation |
| Unknown place ("Xyzabc") | Polite clarification, no crash |
| Airplane mode | Friendly error, no crash |
| Voice: English and Hindi | Transcribes and speaks reply |
| Cold start of backend | App shows loading, not a crash |

---

## 7. Vibe-Coding Prompts (paste into Gemini/Antigravity)

**Prompt 1: Backend**
> Build a FastAPI backend for "WeatherGPT", a weather chatbot for India. Use the `google-genai` Python SDK with Gemini function calling. Implement three tools using the free Open-Meteo APIs (geocoding, forecast, archive): `get_forecast(location, days)`, `get_alerts(location)` (rule-based severe weather detection on forecast data), and `get_climate_trend(location, start_date, end_date)`. Expose `POST /chat` (message, history, language) and `GET /health`. Load the API key from `.env`. Add error handling so a failed API call returns a friendly message. Do not invent API fields; only use fields documented by Open-Meteo.

**Prompt 2: Flutter chat**
> Create a Flutter app (Material 3, Provider) with a chat screen for WeatherGPT. Include message bubbles, a typing indicator, a text field, send and mic buttons, a language dropdown (Auto/English/Hindi/Telugu), and suggestion chips on the empty state. An `ApiService` should POST to `{baseUrl}/chat` with message, history, and language, decoding the response with `utf8.decode(bodyBytes)`. Handle timeouts and errors gracefully.

**Prompt 3: Voice**
> Add voice to the Flutter app using `speech_to_text` and `flutter_tts`. Mic button starts listening in the selected language (en_IN, hi_IN, te_IN), sends the final transcript as a chat message, and reads the bot reply aloud. Add a speaker icon to replay any bot message. Handle missing microphone permission and unavailable locales.

**Prompt 4: Alerts**
> Add an Alerts screen with bottom navigation (Chat, Alerts). It calls `GET /alerts?location=` and shows severity-coloured cards. Also add a warning banner at the top of the chat screen when the user's location has a red or orange alert.

**After every prompt:** run the code, test it, and paste any errors back with the exact error text. Review API parsing and the function-calling code yourself, since LLMs often hallucinate field names and SDK method signatures.

---

## 8. Common Pitfalls

| Problem | Fix |
|---|---|
| App cannot reach backend on emulator | Use `10.0.2.2`, not `localhost` |
| App cannot reach backend on a real phone | Use LAN IP, ngrok, or the deployed URL; phone and PC on the same Wi-Fi |
| Hindi/Telugu text shows as `???` | Decode with `utf8.decode(res.bodyBytes)` |
| Gemini rate-limit errors during demo | Cache repeated answers; keep a screen recording as backup |
| Render free tier is slow on first request | Ping `/health` before presenting |
| Telugu voice not working | Install language pack on the phone; fall back to Hindi/English voice |
| LLM invents weather numbers | System prompt rule + always force a tool call; low temperature |
| API key leaked | Key lives only in backend `.env`; add `.env` to `.gitignore` |

---

## 9. Pitch and Demo

**One-line pitch:** "One conversation, any language, real IMD-grade weather intelligence, for the farmer who cannot read a bulletin."

**Demo flow (3 minutes)**
1. Open the app. A farmer asks by **voice in Telugu**: "Should I spray pesticide tomorrow?"
2. WeatherGPT checks live forecast data and answers in Telugu, speaking it aloud, with a clear yes/no and reason.
3. Show the **Alerts tab**: a heavy-rain or heatwave alert for a district, colour-coded.
4. Ask a **climate question**: "How was this July's rainfall compared to last year?" and show the chart.
5. Close with the architecture slide and the roadmap.

**Slide outline**
1. Problem: fragmented weather info, language and literacy barriers
2. Solution: WeatherGPT (screenshot)
3. Architecture diagram
4. Live demo
5. Impact: farmers, disaster managers, researchers
6. Innovation: tool-calling agent, multilingual voice, honest alert design
7. Roadmap: GFS/WRF ingestion, IMD CAP/WIS 2.0 feeds, FCM push alerts, more languages, offline mode
8. Team and tech stack

**Judge Q&A prep**
- *Is the data accurate?* We use Open-Meteo, which aggregates national weather service model output; the LLM never generates numbers, only explains tool results.
- *Why not RAG?* Weather is live structured data, not a document corpus. Tool-calling is the right pattern.
- *How does it scale?* Stateless FastAPI behind a load balancer, cached forecasts by location and hour, containerised for Kubernetes.
- *Is it official IMD data?* Prototype uses open APIs; production integrates IMD feeds directly (roadmap).
- *What about no internet?* Cached last answer today; SMS/IVR fallback is on the roadmap.

---

## 10. Master Checklist

- [ ] Gemini API key created
- [ ] Repo with `backend/` and `app/`
- [ ] Open-Meteo calls tested in browser
- [ ] `get_forecast`, `get_alerts`, `get_climate_trend` working
- [ ] `/chat` works via curl (English, Hindi, Telugu)
- [ ] Flutter chat UI talking to backend
- [ ] GPS "near me" support
- [ ] Voice input and spoken replies
- [ ] Alerts screen and banner
- [ ] Climate chart
- [ ] Error handling and polish
- [ ] Backend deployed (plus ngrok fallback ready)
- [ ] Release APK tested on a real phone
- [ ] Demo script rehearsed, screen recording saved as backup
- [ ] Slides finished
- [ ] Verified problem statement details on the official SIH portal

---

*Notes: API names, free-tier limits, package versions, and model names change often. Confirm them in the official docs (Open-Meteo, Google AI Studio, pub.dev) when you build. The alert thresholds are illustrative and should be aligned with IMD's official criteria.*
