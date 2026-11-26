"""Aura - native backend.

Talks to Open-Meteo for forecasts and geocoding, BigDataCloud / ipwho.is for
location lookup, and persists places and units with QSettings.
"""

from __future__ import annotations

import json
import os
from datetime import datetime
from urllib.parse import quote

from PySide6.QtCore import Property, QObject, QSettings, QTimer, QUrl, Signal, Slot
from PySide6.QtNetwork import QNetworkAccessManager, QNetworkReply, QNetworkRequest

BASE = os.path.dirname(os.path.abspath(__file__))

CONDITIONS = {
    0: "Clear sky",
    1: "Mainly clear",
    2: "Partly cloudy",
    3: "Overcast",
    45: "Fog",
    48: "Freezing fog",
    51: "Light drizzle",
    53: "Drizzle",
    55: "Heavy drizzle",
    56: "Freezing drizzle",
    57: "Freezing drizzle",
    61: "Light rain",
    63: "Rain",
    65: "Heavy rain",
    66: "Freezing rain",
    67: "Freezing rain",
    71: "Light snow",
    73: "Snow",
    75: "Heavy snow",
    77: "Snow grains",
    80: "Light showers",
    81: "Showers",
    82: "Heavy showers",
    85: "Snow showers",
    86: "Heavy snow showers",
    95: "Thunderstorm",
    96: "Thunderstorm, hail",
    99: "Severe thunderstorm",
}


def _video_key(code: int, is_day: bool) -> str:
    if code == 0:
        return "clear-day" if is_day else "clear-night"
    if code in (1, 2):
        return "partly-day" if is_day else "partly-night"
    if code == 3:
        return "cloudy-day" if is_day else "cloudy-night"
    if code in (45, 48):
        return "fog"
    if code in (51, 53, 55, 56, 57):
        return "drizzle"
    if code in (61, 63, 65, 66, 67):
        return "rain"
    if code in (71, 73, 75, 77, 85, 86):
        return "snow"
    if code in (80, 81, 82):
        return "showers-day" if is_day else "rain"
    if code in (95, 96, 99):
        return "storm"
    return "cloudy-day" if is_day else "cloudy-night"


def _icon_key(code: int, is_day: bool) -> str:
    if code == 0:
        return "clear-day" if is_day else "clear-night"
    if code in (1, 2):
        return "partly-day" if is_day else "partly-night"
    if code == 3:
        return "cloudy"
    if code in (45, 48):
        return "fog"
    if code in (51, 53, 55, 56, 57):
        return "drizzle"
    if code in (61, 63, 65, 66, 67):
        return "rain"
    if code in (71, 73, 75, 77, 85, 86):
        return "snow"
    if code in (80, 81, 82):
        return "showers"
    if code in (95, 96, 99):
        return "storm"
    return "cloudy"


def _num(value, default=0.0) -> float:
    if value is None:
        return default
    try:
        return float(value)
    except (TypeError, ValueError):
        return default


def _int(value, default=0) -> int:
    if value is None:
        return default
    try:
        return int(round(float(value)))
    except (TypeError, ValueError):
        return default


class Backend(QObject):
    dataChanged = Signal()
    unitsChanged = Signal()
    loadingChanged = Signal()
    errorChanged = Signal()
    placesChanged = Signal()
    searchChanged = Signal()
    updatedChanged = Signal()

    def __init__(self) -> None:
        super().__init__()
        self._nam = QNetworkAccessManager(self)
        self._settings = QSettings("Aura", "Weather")
        self._units = self._settings.value("units", "metric") or "metric"
        if self._units not in ("metric", "imperial"):
            self._units = "metric"

        self._data: dict = {}
        self._place: dict | None = None
        self._saved: list = []
        self._search: list = []
        self._searching = False
        self._pending_query = ""
        self._search_seq = 0
        self._loading = False
        self._error = ""
        self._updated = ""
        self._weather_seq = 0
        self._air_seq = 0
        self._places_seq = 0

        self._search_timer = QTimer(self)
        self._search_timer.setSingleShot(True)
        self._search_timer.setInterval(320)
        self._search_timer.timeout.connect(self._run_search)

        self._refresh_timer = QTimer(self)
        self._refresh_timer.setInterval(10 * 60 * 1000)
        self._refresh_timer.timeout.connect(self.refresh)
        self._refresh_timer.start()

        self._load_saved()

    # ------------------------------------------------------------------ props
    @Property("QVariantMap", notify=dataChanged)
    def data(self):
        return self._data

    @Property(str, notify=unitsChanged)
    def units(self):
        return self._units

    @Property(bool, notify=loadingChanged)
    def loading(self):
        return self._loading

    @Property(str, notify=errorChanged)
    def error(self):
        return self._error

    @Property("QVariantList", notify=placesChanged)
    def savedPlaces(self):
        return self._saved

    @Property("QVariantList", notify=searchChanged)
    def searchResults(self):
        return self._search

    @Property(bool, notify=searchChanged)
    def searching(self):
        return self._searching

    @Property(str, notify=updatedChanged)
    def lastUpdated(self):
        return self._updated

    # ------------------------------------------------------------------ utils
    @Slot(str, result=str)
    def asset(self, rel: str) -> str:
        return QUrl.fromLocalFile(os.path.join(BASE, rel)).toString()

    def _set_loading(self, value: bool) -> None:
        if self._loading != value:
            self._loading = value
            self.loadingChanged.emit()

    def _set_error(self, message: str) -> None:
        if self._error != message:
            self._error = message
            self.errorChanged.emit()

    def _persist(self) -> None:
        self._settings.setValue("places", json.dumps(self._saved))
        if self._place:
            self._settings.setValue("active", json.dumps(self._place))

    def _load_saved(self) -> None:
        raw = self._settings.value("places", "[]")
        try:
            parsed = json.loads(raw)
            self._saved = parsed if isinstance(parsed, list) else []
        except (TypeError, ValueError):
            self._saved = []
        for item in self._saved:
            item.setdefault("temp", None)
            item.setdefault("code", None)
            item.setdefault("isDay", True)

    # ------------------------------------------------------------------ network
    def _get(self, url: str, callback) -> None:
        request = QNetworkRequest(QUrl(url))
        request.setHeader(QNetworkRequest.UserAgentHeader, "AuraWeather/1.0")
        reply = self._nam.get(request)

        def done() -> None:
            if reply.error() != QNetworkReply.NetworkError.NoError:
                callback(None, reply.errorString())
            else:
                try:
                    callback(json.loads(bytes(reply.readAll()).decode("utf-8")), "")
                except (ValueError, UnicodeDecodeError) as exc:
                    callback(None, str(exc))
            reply.deleteLater()

        reply.finished.connect(done)

    # ------------------------------------------------------------------ bootstrap
    @Slot()
    def bootstrap(self) -> None:
        raw = self._settings.value("active", "")
        place = None
        try:
            candidate = json.loads(raw) if raw else None
            if isinstance(candidate, dict) and candidate.get("lat") is not None:
                place = candidate
        except (TypeError, ValueError):
            place = None

        if place:
            self._place = {
                "name": place.get("name") or "My location",
                "region": place.get("region") or "",
                "country": place.get("country") or "",
                "lat": float(place["lat"]),
                "lon": float(place["lon"]),
            }
            self.refresh()
        else:
            self.use_my_location()

    @Slot()
    def use_my_location(self) -> None:
        self._set_loading(True)
        self._set_error("")
        url = (
            "https://api.bigdatacloud.net/data/reverse-geocode-client"
            "?localityLanguage=en"
        )
        self._get(url, self._on_ip_bigdata)

    def _on_ip_bigdata(self, payload, error: str) -> None:
        if payload and payload.get("latitude") is not None:
            self._apply_location(payload, "bigdata")
            return
        self._get("https://ipwho.is/", self._on_ip_ipwho)

    def _on_ip_ipwho(self, payload, error: str) -> None:
        if payload and payload.get("success", True) and payload.get("latitude") is not None:
            self._apply_location(payload, "ipwho")
            return
        self._set_loading(False)
        self._set_error("Could not detect your location. Search for a city to begin.")
        self._place = {
            "name": "San Francisco",
            "region": "California",
            "country": "United States",
            "lat": 37.7749,
            "lon": -122.4194,
        }
        self.refresh()

    def _apply_location(self, payload: dict, source: str) -> None:
        lat = payload.get("latitude")
        lon = payload.get("longitude")
        if source == "ipwho":
            name = payload.get("city") or "My location"
            region = payload.get("region") or ""
            country = payload.get("country") or ""
        else:
            name = (
                payload.get("city")
                or payload.get("locality")
                or payload.get("principalSubdivision")
                or "My location"
            )
            region = payload.get("principalSubdivision") or ""
            country = payload.get("countryName") or ""
        self._place = {
            "name": name,
            "region": region,
            "country": country,
            "lat": float(lat),
            "lon": float(lon),
        }
        self._set_loading(False)
        self.refresh()

    # ------------------------------------------------------------------ weather
    @Slot()
    def refresh(self) -> None:
        if not self._place:
            self.use_my_location()
            return
        self._set_loading(True)
        self._set_error("")
        self._weather_seq += 1
        seq = self._weather_seq
        lat = self._place["lat"]
        lon = self._place["lon"]
        current = ",".join(
            [
                "temperature_2m",
                "relative_humidity_2m",
                "apparent_temperature",
                "is_day",
                "precipitation",
                "rain",
                "showers",
                "snowfall",
                "weather_code",
                "cloud_cover",
                "pressure_msl",
                "wind_speed_10m",
                "wind_direction_10m",
                "wind_gusts_10m",
                "visibility",
                "dew_point_2m",
                "uv_index",
            ]
        )
        hourly = ",".join(
            [
                "temperature_2m",
                "apparent_temperature",
                "precipitation_probability",
                "precipitation",
                "weather_code",
                "wind_speed_10m",
                "wind_direction_10m",
                "relative_humidity_2m",
                "is_day",
                "uv_index",
                "visibility",
                "dew_point_2m",
                "cloud_cover",
            ]
        )
        daily = ",".join(
            [
                "weather_code",
                "temperature_2m_max",
                "temperature_2m_min",
                "apparent_temperature_max",
                "apparent_temperature_min",
                "sunrise",
                "sunset",
                "uv_index_max",
                "precipitation_sum",
                "precipitation_probability_max",
                "wind_speed_10m_max",
                "wind_gusts_10m_max",
                "wind_direction_10m_dominant",
            ]
        )
        url = (
            "https://api.open-meteo.com/v1/forecast"
            f"?latitude={lat}&longitude={lon}"
            f"&current={current}&hourly={hourly}&daily={daily}"
            "&timezone=auto&forecast_days=10"
        )
        self._get(url, lambda payload, err: self._on_weather(payload, err, seq))

    def _on_weather(self, payload, error: str, seq: int) -> None:
        if seq != self._weather_seq:
            return
        if not payload or "current" not in payload:
            self._set_loading(False)
            self._set_error(error or "Weather is unavailable right now.")
            return

        cur = payload.get("current", {})
        hourly_raw = payload.get("hourly", {})
        daily_raw = payload.get("daily", {})
        now = cur.get("time", "")
        code = _int(cur.get("weather_code"), 0)
        is_day = bool(_int(cur.get("is_day"), 1))

        times = hourly_raw.get("time", [])
        start = 0
        for i, stamp in enumerate(times):
            if stamp >= now:
                start = i
                break
        hourly = []
        for i in range(start, min(start + 48, len(times))):
            h_code = _int(hourly_raw.get("weather_code", [0] * len(times))[i], 0)
            h_day = bool(_int(hourly_raw.get("is_day", [1] * len(times))[i], 1))
            hourly.append(
                {
                    "time": times[i],
                    "temp": _num(hourly_raw.get("temperature_2m", [0] * len(times))[i]),
                    "feels": _num(hourly_raw.get("apparent_temperature", [0] * len(times))[i]),
                    "code": h_code,
                    "isDay": h_day,
                    "icon": _icon_key(h_code, h_day),
                    "condition": CONDITIONS.get(h_code, "Cloudy"),
                    "precipProb": _int(
                        hourly_raw.get("precipitation_probability", [0] * len(times))[i]
                    ),
                    "precip": _num(hourly_raw.get("precipitation", [0] * len(times))[i]),
                    "wind": _num(hourly_raw.get("wind_speed_10m", [0] * len(times))[i]),
                    "windDir": _num(hourly_raw.get("wind_direction_10m", [0] * len(times))[i]),
                    "humidity": _int(
                        hourly_raw.get("relative_humidity_2m", [0] * len(times))[i]
                    ),
                    "uv": _num(hourly_raw.get("uv_index", [0] * len(times))[i]),
                    "visibility": _num(hourly_raw.get("visibility", [0] * len(times))[i]),
                    "dew": _num(hourly_raw.get("dew_point_2m", [0] * len(times))[i]),
                    "cloud": _int(hourly_raw.get("cloud_cover", [0] * len(times))[i]),
                }
            )

        daily = []
        dates = daily_raw.get("time", [])
        for i, date in enumerate(dates[:10]):
            d_code = _int(daily_raw.get("weather_code", [0] * len(dates))[i], 0)
            daily.append(
                {
                    "date": date,
                    "code": d_code,
                    "icon": _icon_key(d_code, True),
                    "condition": CONDITIONS.get(d_code, "Cloudy"),
                    "max": _num(daily_raw.get("temperature_2m_max", [0] * len(dates))[i]),
                    "min": _num(daily_raw.get("temperature_2m_min", [0] * len(dates))[i]),
                    "maxFeels": _num(
                        daily_raw.get("apparent_temperature_max", [0] * len(dates))[i]
                    ),
                    "minFeels": _num(
                        daily_raw.get("apparent_temperature_min", [0] * len(dates))[i]
                    ),
                    "precipProb": _int(
                        daily_raw.get("precipitation_probability_max", [0] * len(dates))[i]
                    ),
                    "precipSum": _num(daily_raw.get("precipitation_sum", [0] * len(dates))[i]),
                    "sunrise": (daily_raw.get("sunrise") or [""] * len(dates))[i],
                    "sunset": (daily_raw.get("sunset") or [""] * len(dates))[i],
                    "uvMax": _num(daily_raw.get("uv_index_max", [0] * len(dates))[i]),
                    "windMax": _num(
                        daily_raw.get("wind_speed_10m_max", [0] * len(dates))[i]
                    ),
                    "gustMax": _num(
                        daily_raw.get("wind_gusts_10m_max", [0] * len(dates))[i]
                    ),
                    "windDir": _num(
                        daily_raw.get("wind_direction_10m_dominant", [0] * len(dates))[i]
                    ),
                }
            )

        today = daily[0] if daily else {}
        place = dict(self._place or {})
        place["timezone"] = payload.get("timezone", "")

        self._data = {
            "place": place,
            "video": _video_key(code, is_day),
            "icon": _icon_key(code, is_day),
            "condition": CONDITIONS.get(code, "Cloudy"),
            "current": {
                "time": now,
                "temp": _num(cur.get("temperature_2m")),
                "feels": _num(cur.get("apparent_temperature")),
                "code": code,
                "isDay": is_day,
                "humidity": _int(cur.get("relative_humidity_2m")),
                "precip": _num(cur.get("precipitation")),
                "rain": _num(cur.get("rain")),
                "showers": _num(cur.get("showers")),
                "snow": _num(cur.get("snowfall")),
                "cloud": _int(cur.get("cloud_cover")),
                "pressure": _num(cur.get("pressure_msl")),
                "wind": _num(cur.get("wind_speed_10m")),
                "windDir": _num(cur.get("wind_direction_10m")),
                "gust": _num(cur.get("wind_gusts_10m")),
                "visibility": _num(cur.get("visibility")),
                "dew": _num(cur.get("dew_point_2m")),
                "uv": _num(cur.get("uv_index")),
                "aqi": None,
                "aqiUs": None,
                "pm25": None,
                "pm10": None,
                "ozone": None,
                "no2": None,
                "so2": None,
            },
            "today": {
                "max": _num(today.get("max")),
                "min": _num(today.get("min")),
                "sunrise": today.get("sunrise", ""),
                "sunset": today.get("sunset", ""),
                "precipProb": _int(today.get("precipProb")),
                "uvMax": _num(today.get("uvMax")),
                "windMax": _num(today.get("windMax")),
                "precipSum": _num(today.get("precipSum")),
            },
            "hourly": hourly,
            "daily": daily,
        }
        self._updated = datetime.now().strftime("%H:%M")
        self._set_loading(False)
        self._set_error("")
        self._persist()
        self.dataChanged.emit()
        self.updatedChanged.emit()
        self._fetch_air()
        self.refresh_place_temps()

    # ------------------------------------------------------------------ air
    def _fetch_air(self) -> None:
        if not self._place:
            return
        self._air_seq += 1
        seq = self._air_seq
        lat = self._place["lat"]
        lon = self._place["lon"]
        url = (
            "https://air-quality-api.open-meteo.com/v1/air-quality"
            f"?latitude={lat}&longitude={lon}"
            "&current=european_aqi,us_aqi,pm10,pm2_5,carbon_monoxide,"
            "nitrogen_dioxide,sulphur_dioxide,ozone"
        )
        self._get(url, lambda payload, err: self._on_air(payload, err, seq))

    def _on_air(self, payload, error: str, seq: int) -> None:
        if seq != self._air_seq or not payload or not self._data:
            return
        cur = payload.get("current") or {}
        target = self._data.get("current")
        if not target:
            return
        if cur.get("european_aqi") is not None:
            target["aqi"] = _int(cur.get("european_aqi"))
            target["aqiUs"] = _int(cur.get("us_aqi"))
            target["pm25"] = _num(cur.get("pm2_5"))
            target["pm10"] = _num(cur.get("pm10"))
            target["ozone"] = _num(cur.get("ozone"))
            target["no2"] = _num(cur.get("nitrogen_dioxide"))
            target["so2"] = _num(cur.get("sulphur_dioxide"))
            self._data["current"] = target
            self.dataChanged.emit()

    # ------------------------------------------------------------------ search
    @Slot(str)
    def search(self, query: str) -> None:
        self._pending_query = query.strip()
        if len(self._pending_query) < 2:
            self._search = []
            self._searching = False
            self.searchChanged.emit()
            return
        self._searching = True
        self.searchChanged.emit()
        self._search_timer.start()

    def _run_search(self) -> None:
        query = self._pending_query
        if len(query) < 2:
            return
        self._search_seq += 1
        seq = self._search_seq
        url = (
            "https://geocoding-api.open-meteo.com/v1/search"
            f"?name={quote(query)}&count=7&language=en&format=json"
        )
        self._get(url, lambda payload, err: self._on_search(payload, err, seq))

    def _on_search(self, payload, error: str, seq: int) -> None:
        if seq != self._search_seq:
            return
        self._searching = False
        results = []
        if payload:
            for item in payload.get("results", []) or []:
                results.append(
                    {
                        "name": item.get("name") or "",
                        "region": item.get("admin1") or "",
                        "country": item.get("country") or "",
                        "lat": item.get("latitude"),
                        "lon": item.get("longitude"),
                        "population": item.get("population") or 0,
                    }
                )
        self._search = results
        if error:
            self._set_error("Search is unavailable. Check your connection.")
        self.searchChanged.emit()

    @Slot(int)
    def chooseSearchResult(self, index: int) -> None:
        if index < 0 or index >= len(self._search):
            return
        item = self._search[index]
        self._place = {
            "name": item.get("name") or "My location",
            "region": item.get("region") or "",
            "country": item.get("country") or "",
            "lat": float(item.get("lat") or 0),
            "lon": float(item.get("lon") or 0),
        }
        self._search = []
        self._searching = False
        self.searchChanged.emit()
        self._set_loading(True)
        self.refresh()

    @Slot()
    def clearSearch(self) -> None:
        self._search = []
        self._searching = False
        self.searchChanged.emit()

    # ------------------------------------------------------------------ places
    def _is_saved(self) -> bool:
        if not self._place:
            return False
        for item in self._saved:
            if (
                abs(float(item.get("lat", 0)) - self._place["lat"]) < 0.02
                and abs(float(item.get("lon", 0)) - self._place["lon"]) < 0.02
            ):
                return True
        return False

    @Property(bool, notify=placesChanged)
    def currentSaved(self):
        return self._is_saved()

    @Slot()
    def toggleCurrentPlace(self) -> None:
        if not self._place:
            return
        for i, item in enumerate(self._saved):
            if (
                abs(float(item.get("lat", 0)) - self._place["lat"]) < 0.02
                and abs(float(item.get("lon", 0)) - self._place["lon"]) < 0.02
            ):
                del self._saved[i]
                self._persist()
                self.placesChanged.emit()
                self._set_error("")
                return
        self._saved.insert(
            0,
            {
                "name": self._place["name"],
                "region": self._place.get("region", ""),
                "country": self._place.get("country", ""),
                "lat": self._place["lat"],
                "lon": self._place["lon"],
                "temp": None,
                "code": None,
                "isDay": True,
            },
        )
        self._persist()
        self.placesChanged.emit()
        self.refresh_place_temps()

    @Slot(int)
    def selectPlace(self, index: int) -> None:
        if index < 0 or index >= len(self._saved):
            return
        item = self._saved[index]
        self._place = {
            "name": item.get("name") or "My location",
            "region": item.get("region") or "",
            "country": item.get("country") or "",
            "lat": float(item.get("lat") or 0),
            "lon": float(item.get("lon") or 0),
        }
        self._set_loading(True)
        self.refresh()

    @Slot(int)
    def removePlace(self, index: int) -> None:
        if 0 <= index < len(self._saved):
            del self._saved[index]
            self._persist()
            self.placesChanged.emit()

    def refresh_place_temps(self) -> None:
        if not self._saved:
            return
        self._places_seq += 1
        seq = self._places_seq
        lats = ",".join(f"{float(item.get('lat', 0)):.4f}" for item in self._saved)
        lons = ",".join(f"{float(item.get('lon', 0)):.4f}" for item in self._saved)
        url = (
            "https://api.open-meteo.com/v1/forecast"
            f"?latitude={lats}&longitude={lons}"
            "&current=temperature_2m,weather_code,is_day"
        )
        self._get(url, lambda payload, err: self._on_place_temps(payload, err, seq))

    def _on_place_temps(self, payload, error: str, seq: int) -> None:
        if seq != self._places_seq or not payload:
            return
        entries = payload if isinstance(payload, list) else [payload]
        for i, entry in enumerate(entries[: len(self._saved)]):
            cur = (entry or {}).get("current") or {}
            if cur.get("temperature_2m") is None:
                continue
            self._saved[i]["temp"] = _num(cur.get("temperature_2m"))
            self._saved[i]["code"] = _int(cur.get("weather_code"), 0)
            self._saved[i]["isDay"] = bool(_int(cur.get("is_day"), 1))
        self.placesChanged.emit()

    # ------------------------------------------------------------------ units
    @Slot(str)
    def setUnits(self, unit: str) -> None:
        if unit not in ("metric", "imperial") or unit == self._units:
            return
        self._units = unit
        self._settings.setValue("units", unit)
        self.unitsChanged.emit()
