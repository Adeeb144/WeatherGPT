<p align="center">
  <img src="https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Travel%20and%20places/Sun%20Behind%20Large%20Cloud.png" alt="WeatherGPT Banner" width="150" />
</p>

<h1 align="center">🌤️ WeatherGPT</h1>

<p align="center">
  <em>An Intelligent, Voice-Powered Weather Assistant Built for the <strong>SIH26068 Hackathon</strong></em>
</p>

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white" alt="Flutter"></a>
  <a href="https://fastapi.tiangolo.com/"><img src="https://img.shields.io/badge/FastAPI-%23009688.svg?style=for-the-badge&logo=fastapi&logoColor=white" alt="FastAPI"></a>
  <a href="https://aistudio.google.com/"><img src="https://img.shields.io/badge/Google%20Gemini-%238E75B2.svg?style=for-the-badge&logo=google&logoColor=white" alt="Gemini API"></a>
  <a href="https://open-meteo.com/"><img src="https://img.shields.io/badge/Open--Meteo-%232D3142.svg?style=for-the-badge&logo=icloud&logoColor=white" alt="Open-Meteo"></a>
</p>

---

<br>

## 🌌 The Vision
> "More than just a forecast. A completely conversational, localized, and intelligent weather companion."

**WeatherGPT** represents the next evolution of weather applications. By marrying the lightning-fast performance of **Flutter** with the profound reasoning capabilities of **Google Gemini**, WeatherGPT transforms raw meteorological data into actionable, human-like advice. 

---

<br>

## ✨ Dazzling Features

<table>
  <tr>
    <td width="50%">
      <h3>🗣️ Conversational AI</h3>
      <p>Speak naturally. Ask <em>"Do I need an umbrella today?"</em> or <em>"Is it good weather for planting rice?"</em> and get context-aware, spoken responses.</p>
    </td>
    <td width="50%">
      <h3>🌍 Multilingual By Design</h3>
      <p>Break the language barrier. Native text-to-speech and speech-to-text support for <b>English, Hindi, and Telugu</b>.</p>
    </td>
  </tr>
  <tr>
    <td>
      <h3>🚨 Real-Time Severe Alerts</h3>
      <p>Color-coded hazard warnings (Red, Orange, Yellow) based on strict IMD logic. Never be caught off-guard by extreme weather.</p>
    </td>
    <td>
      <h3>📈 Dynamic Climate Trends</h3>
      <p>Visualize historical climate data with interactive, fluid charts tracking 12-month temperature and rainfall metrics.</p>
    </td>
  </tr>
</table>

<br>

---

<br>

## 📱 App Previews

<p align="center">
  <img src="https://via.placeholder.com/250x500/000000/FFFFFF/?text=AI+Chat+%26+Voice" width="28%" />
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="https://via.placeholder.com/250x500/FF4500/FFFFFF/?text=Severe+Alerts" width="28%" />
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="https://via.placeholder.com/250x500/02569B/FFFFFF/?text=Climate+Charts" width="28%" />
</p>
<p align="center">
  <em>(Replace these placeholders with your actual app screenshots!)</em>
</p>

<br>

---

<br>

## ⚙️ Architecture & Tech Stack

The system is decoupled into a robust Python backend and a beautiful Flutter frontend, ensuring scalability and a premium user experience.

<details>
<summary><b>🔹 Frontend: Flutter Mobile App</b> (Click to expand)</summary>

- **Framework**: Flutter (Material 3 UI Design)
- **State Management**: `Provider` architecture
- **Core Packages**: 
  - `speech_to_text` (Voice recognition)
  - `flutter_tts` (Native Text-to-Speech)
  - `geolocator` (Precise GPS coordinates)
  - `fl_chart` (Data visualization)
</details>

<details>
<summary><b>🔹 Backend: FastAPI & AI Engine</b> (Click to expand)</summary>

- **Framework**: Python 3.10+ & `FastAPI`
- **AI Brain**: `google-genai` SDK via Gemini Function Calling
- **Data Providers**: Open-Meteo REST APIs (100% Free Tier)
  - Current Weather & Forecasts
  - Reverse Geocoding
  - Historical Archive Data
</details>

<br>

---

<br>

## 🚀 Getting Started

Follow these steps to run the project on your local machine.

### 1️⃣ Spin Up the Backend

```bash
# Navigate to the backend directory
cd backend

# Create and activate a virtual environment
python -m venv venv
source venv/bin/activate  # On Windows use: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

Create a `.env` file in the `backend/` directory and add your key:
```env
GEMINI_API_KEY=your_google_gemini_key_here
```

Start the lightning-fast Uvicorn server:
```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### 2️⃣ Launch the App

```bash
# Open a new terminal and navigate to the app directory
cd app

# Fetch Flutter dependencies
flutter pub get
```

Before running, tell the app where your backend is located. Open `app/lib/services/api_service.dart` and update `baseUrl`:
- **For Local Emulator**: `http://10.0.2.2:8000`
- **For Physical Device**: `http://<your-pc-ip>:8000`

Fire it up:
```bash
flutter run
```

<br>

---

<p align="center">
  Built with ❤️ for the <strong>SIH26068 Hackathon</strong>. <br>
  Open-source under the MIT License.
</p>