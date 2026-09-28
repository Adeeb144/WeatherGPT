import os
from dotenv import load_dotenv
from google import genai
from google.genai import types
from tools import get_forecast, get_alerts, get_climate_trend, get_forecast_by_coords

load_dotenv()
client = genai.Client(api_key=os.environ.get("GEMINI_API_KEY", ""))

MODEL = "gemini-2.5-flash"

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
            role=turn["role"], parts=[types.Part.from_text(text=turn["text"])]))
    contents.append(types.Content(role="user", parts=[types.Part.from_text(text=message)]))

    try:
        response = client.models.generate_content(
            model=MODEL,
            contents=contents,
            config=types.GenerateContentConfig(
                system_instruction=system,
                tools=[get_forecast, get_alerts, get_climate_trend, get_forecast_by_coords],
                temperature=0.3,
            ),
        )
        return response.text
    except Exception as e:
        raise Exception(f"Failed to generate response: {str(e)}")
