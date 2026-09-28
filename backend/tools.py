import httpx

GEO_URL = "https://geocoding-api.open-meteo.com/v1/search"
FORECAST_URL = "https://api.open-meteo.com/v1/forecast"
ARCHIVE_URL = "https://archive-api.open-meteo.com/v1/archive"


def _geocode(location: str):
    if "," in location:
        try:
            parts = location.split(",")
            return {"name": "Your Location", "state": "", "lat": float(parts[0].strip()), "lon": float(parts[1].strip())}
        except:
            pass
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
    try:
        place = _geocode(location)
        if not place:
            return {"error": f"Could not find location '{location}'"}
        params = {
            "latitude": place["lat"], "longitude": place["lon"],
            "current": "temperature_2m,relative_humidity_2m,wind_speed_10m,precipitation",
            "daily": "temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max,wind_speed_10m_max",
            "forecast_days": max(1, min(days, 7)),
            "timezone": "Asia/Kolkata",
        }
        r = httpx.get(FORECAST_URL, params=params, timeout=15)
        r.raise_for_status()
        return {"place": place, "data": r.json()}
    except Exception as e:
        return {"error": f"Failed to get forecast: {str(e)}"}


def get_climate_trend(location: str, start_date: str, end_date: str) -> dict:
    """Get historical daily weather for a location to analyse climate trends.

    Args:
        location: City or town name.
        start_date: Start date in YYYY-MM-DD format.
        end_date: End date in YYYY-MM-DD format.
    """
    try:
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
    except Exception as e:
        return {"error": f"Failed to get climate trend: {str(e)}"}


def get_alerts(location: str) -> dict:
    """Check the next 3 days for extreme weather at a location.

    Args:
        location: City or town name.
    """
    try:
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
    except Exception as e:
        return {"error": f"Failed to get alerts: {str(e)}"}

def get_forecast_by_coords(lat: float, lon: float, days: int = 3) -> dict:
    """Get current weather and daily forecast for specific coordinates.

    Args:
        lat: Latitude of the location.
        lon: Longitude of the location.
        days: Number of forecast days (1 to 7).
    """
    try:
        params = {
            "latitude": lat, "longitude": lon,
            "current": "temperature_2m,relative_humidity_2m,wind_speed_10m,precipitation",
            "daily": "temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max,wind_speed_10m_max",
            "forecast_days": max(1, min(days, 7)),
            "timezone": "Asia/Kolkata",
        }
        r = httpx.get(FORECAST_URL, params=params, timeout=15)
        r.raise_for_status()
        return {"place": {"lat": lat, "lon": lon}, "data": r.json()}
    except Exception as e:
        return {"error": f"Failed to get forecast: {str(e)}"}
