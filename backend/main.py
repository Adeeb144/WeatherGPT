from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from agent import run_agent
from tools import get_alerts, _geocode, ARCHIVE_URL
import httpx
from datetime import date, timedelta

app = FastAPI(title="WeatherGPT API")
app.add_middleware(CORSMiddleware, allow_origins=["*"],
                   allow_methods=["*"], allow_headers=["*"])

@app.get("/health")
def health():
    return {"status": "ok"}

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

@app.get("/alerts")
def alerts_endpoint(location: str):
    return get_alerts(location)

@app.get("/climate")
def climate_endpoint(location: str):
    try:
        place = _geocode(location)
        if not place:
            return {"error": f"Could not find location '{location}'"}
        
        end = date.today() - timedelta(days=5)
        start = end - timedelta(days=365)
        
        params = {
            "latitude": place["lat"], "longitude": place["lon"],
            "start_date": start.isoformat(), "end_date": end.isoformat(),
            "daily": "temperature_2m_mean,precipitation_sum",
            "timezone": "Asia/Kolkata",
        }
        r = httpx.get(ARCHIVE_URL, params=params, timeout=20)
        r.raise_for_status()
        d = r.json().get("daily", {})
        
        times = d.get("time", [])
        temps = d.get("temperature_2m_mean", [])
        rains = d.get("precipitation_sum", [])
        
        monthly = {}
        for i, t in enumerate(times):
            if not t: continue
            month = t[:7]
            if month not in monthly:
                monthly[month] = {"temps": [], "rains": []}
            if temps[i] is not None:
                monthly[month]["temps"].append(temps[i])
            if rains[i] is not None:
                monthly[month]["rains"].append(rains[i])
                
        results = []
        for m in sorted(monthly.keys()):
            mts = monthly[m]["temps"]
            mrs = monthly[m]["rains"]
            avg_t = sum(mts)/len(mts) if mts else 0
            tot_r = sum(mrs) if mrs else 0
            results.append({"month": m, "avg_temp": round(avg_t, 1), "total_rain": round(tot_r, 1)})
            
        return {"place": place, "monthly": results}
    except Exception as e:
        return {"error": str(e)}
