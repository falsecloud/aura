/* =========================================================
   Aura — weather app logic
   Data: Open-Meteo (forecast + air quality + geocoding)
   Geolocation: browser GNSS → reverse geocode → IP fallback
   ========================================================= */
(function () {
  "use strict";

  const ENDPOINTS = {
    forecast: "https://api.open-meteo.com/v1/forecast",
    air: "https://air-quality-api.open-meteo.com/v1/air-quality",
    geocode: "https://geocoding-api.open-meteo.com/v1/search"
  };

  const DEFAULT_PLACE = {
    name: "London",
    region: "England, United Kingdom",
    lat: 51.5074,
    lon: -0.1278,
    timezone: "Europe/London"
  };

  const STORE = { unit: "aura.unit", place: "aura.place" };

  const SKIES = {
    "clear-day": {
      bg: "radial-gradient(120% 110% at 12% -8%, #8ed3f5 0%, #4d9fe0 30%, #2268b0 62%, #123c73 100%)",
      orbs: ["#ffe3a3", "#63cdff", "#a99bff"],
      accent: "#ffd977"
    },
    "clear-night": {
      bg: "radial-gradient(120% 110% at 18% -10%, #33427f 0%, #1d2450 42%, #101532 72%, #070a18 100%)",
      orbs: ["#5b74ff", "#a06bdc", "#2f7fd0"],
      accent: "#c3d0ff"
    },
    "partly-day": {
      bg: "radial-gradient(120% 110% at 8% -6%, #a7d6ec 0%, #639dbd 32%, #2f6a92 64%, #143449 100%)",
      orbs: ["#ffe9b0", "#7fd8ff", "#b3a0ff"],
      accent: "#ffe29a"
    },
    "partly-night": {
      bg: "radial-gradient(120% 110% at 15% -8%, #2e3c72 0%, #1b2346 44%, #0d1226 100%)",
      orbs: ["#6f84ff", "#9a7bd8", "#2a6bb0"],
      accent: "#cfd8ff"
    },
    "cloudy-day": {
      bg: "radial-gradient(120% 110% at 10% -6%, #b7c7d4 0%, #8195a8 32%, #536577 64%, #2b3947 100%)",
      orbs: ["#e2ecf7", "#9fb6cc", "#c8b6ff"],
      accent: "#e8f1ff"
    },
    "cloudy-night": {
      bg: "radial-gradient(120% 110% at 12% -8%, #353f57 0%, #232b3d 42%, #11151f 100%)",
      orbs: ["#6d7fa3", "#8d7fbe", "#2f6b96"],
      accent: "#d5dff0"
    },
    fog: {
      bg: "radial-gradient(120% 110% at 50% 0%, #aebbbf 0%, #8a989e 38%, #5e6b72 70%, #38434a 100%)",
      orbs: ["#e6eef0", "#a9bcc4", "#c0b7d6"],
      accent: "#eef4f6"
    },
    rain: {
      bg: "radial-gradient(120% 110% at 20% -10%, #6e94a8 0%, #476a80 34%, #2b4658 66%, #16232e 100%)",
      orbs: ["#7fc4e8", "#5d8fc8", "#9b8fd8"],
      accent: "#9ad8ff"
    },
    drizzle: {
      bg: "radial-gradient(120% 110% at 20% -10%, #82a6b9 0%, #587d92 34%, #365366 66%, #1c2c37 100%)",
      orbs: ["#96d5f2", "#6da0d4", "#a89ce2"],
      accent: "#b3e4ff"
    },
    "showers-day": {
      bg: "radial-gradient(120% 110% at 14% -8%, #9fc6d4 0%, #6b93a6 34%, #3f6072 66%, #20323e 100%)",
      orbs: ["#ffe1a6", "#79c8ef", "#a79cf0"],
      accent: "#c6e6ff"
    },
    snow: {
      bg: "radial-gradient(120% 110% at 20% -8%, #d3e2ee 0%, #a7bccb 34%, #71889c 68%, #435362 100%)",
      orbs: ["#ffffff", "#c2dcf5", "#b8c4ff"],
      accent: "#eaf5ff"
    },
    storm: {
      bg: "radial-gradient(120% 110% at 22% -10%, #4b4a72 0%, #33334f 36%, #1e2036 68%, #0b0c18 100%)",
      orbs: ["#8b7bff", "#4f6bd8", "#b07bd0"],
      accent: "#d3c4ff"
    }
  };

  /* Free, watermark-free stock footage (Mixkit licence) per sky. */
  const WEATHER_VIDEOS = {
    "clear-day": "media/clear-day.mp4",
    "clear-night": "media/clear-night.mp4",
    "partly-day": "media/partly-day.mp4",
    "partly-night": "media/partly-night.mp4",
    "cloudy-day": "media/cloudy-day.mp4",
    "cloudy-night": "media/cloudy-night.mp4",
    fog: "media/fog.mp4",
    drizzle: "media/drizzle.mp4",
    rain: "media/rain.mp4",
    "showers-day": "media/showers-day.mp4",
    snow: "media/snow.mp4",
    storm: "media/storm.mp4"
  };

  const COMPASS = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"];

  const SVG = {
    drop: `<svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M12 2.7c0 0-6 7.1-6 11.1a6 6 0 0 0 12 0c0-4-6-11.1-6-11.1Z"/></svg>`,
    pin: `<svg class="place-pin" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 21s7-6.1 7-11a7 7 0 1 0-14 0c0 4.9 7 11 7 11Z"/><circle cx="12" cy="10" r="2.5"/></svg>`,
    wind: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 8h10.5A2.8 2.8 0 1 0 10.7 4"/><path d="M3 12h14.2A2.8 2.8 0 1 1 14.4 16"/><path d="M3 16h7"/></svg>`,
    humidity: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 3s6 6.6 6 10.6a6 6 0 0 1-12 0C6 9.6 12 3 12 3Z"/><path d="M9.4 14.6a2.8 2.8 0 0 0 2.6 2.1"/></svg>`,
    sun: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" aria-hidden="true"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M2 12h2M20 12h2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M19.1 4.9l-1.4 1.4M6.3 17.7l-1.4 1.4"/></svg>`,
    sunrise: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 3v4"/><path d="M5 18a7 7 0 0 1 14 0"/><path d="M2 22h20"/><path d="M4.5 9.5 6 8M19.5 9.5 18 8"/><path d="m8 6 4-3 4 3"/></svg>`,
    sunset: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 8V3"/><path d="M5 18a7 7 0 0 1 14 0"/><path d="M2 22h20"/><path d="M4.5 9.5 6 8M19.5 9.5 18 8"/><path d="m8 8 4 3 4-3"/></svg>`,
    thermo: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M14 14.8V5a2 2 0 0 0-4 0v9.8a4 4 0 1 0 4 0Z"/><path d="M12 9v6"/></svg>`,
    raincloud: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M7 15a4 4 0 0 1 .6-8A5.5 5.5 0 0 1 18 8.5a3.5 3.5 0 0 1 .3 6.5"/><path d="M8 18.5v1.5M12 17.5v2.5M16 18.5v1.5"/></svg>`,
    gauge: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M4.2 18a9 9 0 1 1 15.6 0"/><path d="m12 13 3.5-4"/><circle cx="12" cy="14" r="1.4"/></svg>`,
    leaf: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M4 20c0-8 5-13 16-14 1 11-4 16-12 16"/><path d="M4 20c3-5 7-8 12-9"/></svg>`,
    cloud: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M6.5 18a4.5 4.5 0 0 1 .4-9A6 6 0 0 1 18.6 10.7 3.7 3.7 0 0 1 18 18Z"/></svg>`,
    chevron: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m6 9 6 6 6-6"/></svg>`
  };

  const $ = (sel) => document.querySelector(sel);
  const root = document.documentElement;

  const el = {
    hero: $("#hero"),
    hourly: $("#hourlyBody"),
    hourlySub: $("#hourlySub"),
    daily: $("#dailyBody"),
    tiles: $("#tiles"),
    search: $("#searchInput"),
    results: $("#results"),
    locate: $("#locateBtn"),
    refresh: $("#refreshBtn"),
    updated: $("#updatedAt"),
    videoA: $("#videoA"),
    videoB: $("#videoB"),
    loader: $("#loader"),
    loaderSub: $("#loaderSub"),
    toast: $("#toast")
  };

  const state = {
    unit: readStore(STORE.unit) === "f" ? "f" : "c",
    place: null,
    data: null,
    air: null,
    notice: null,
    pending: false,
    results: [],
    activeResult: -1,
    skyToggle: false,
    lastLoaded: 0,
    videoKey: null,
    videoToggle: false,
    videoToken: 0
  };

  /* ---------------------------------------------------------
     small utilities
     --------------------------------------------------------- */

  function readStore(key) {
    try { return localStorage.getItem(key); } catch (e) { return null; }
  }
  function writeStore(key, value) {
    try { localStorage.setItem(key, value); } catch (e) { /* private mode */ }
  }
  function esc(value) {
    return String(value == null ? "" : value).replace(/[&<>"']/g, (c) => ({
      "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;"
    }[c]));
  }
  const reduceMotion = () => window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  const conv = (c) => (state.unit === "f" ? (c * 9) / 5 + 32 : c);
  const t = (c) => (c == null || Number.isNaN(c) ? "—" : `${Math.round(conv(c))}°`);
  const tRaw = (c) => (c == null || Number.isNaN(c) ? "—" : String(Math.round(conv(c))));
  const wind = (kmh) =>
    kmh == null || Number.isNaN(kmh)
      ? "—"
      : state.unit === "f"
      ? `${Math.round(kmh * 0.621371)} mph`
      : `${Math.round(kmh)} km/h`;
  const precip = (mm) => {
    if (mm == null || Number.isNaN(mm)) return "—";
    if (state.unit === "f") {
      const inches = mm / 25.4;
      return inches >= 0.01 ? `${inches.toFixed(2)} in` : `${(inches * 1000).toFixed(0)} mil`;
    }
    return mm >= 1 ? `${mm.toFixed(1)} mm` : `${mm.toFixed(1)} mm`;
  };
  const compass = (deg) => (deg == null ? "—" : COMPASS[Math.round(deg / 22.5) % 16]);

  const timeLabel = (iso) => {
    const d = new Date(iso);
    return d.toLocaleTimeString("en-GB", { hour: "numeric", hour12: true }).replace(/\s/g, " ");
  };
  const weekday = (iso) => new Date(`${iso}T12:00:00`).toLocaleDateString("en-GB", { weekday: "short" });
  const dayMonth = (iso) => new Date(`${iso}T12:00:00`).toLocaleDateString("en-GB", { day: "numeric", month: "short" });

  function localClock(timeZone) {
    try {
      return new Intl.DateTimeFormat("en-GB", {
        timeZone, hour: "numeric", minute: "2-digit", hour12: true
      }).format(new Date());
    } catch (e) {
      return new Date().toLocaleTimeString("en-GB", { hour: "numeric", minute: "2-digit", hour12: true });
    }
  }
  function localDate(timeZone) {
    try {
      return new Intl.DateTimeFormat("en-GB", {
        timeZone, weekday: "long", day: "numeric", month: "long"
      }).format(new Date());
    } catch (e) {
      return new Date().toLocaleDateString("en-GB", { weekday: "long", day: "numeric", month: "long" });
    }
  }

  const uvLevel = (uv) => {
    if (uv == null) return "—";
    if (uv < 3) return "Low";
    if (uv < 6) return "Moderate";
    if (uv < 8) return "High";
    if (uv < 11) return "Very high";
    return "Extreme";
  };

  const aqiBand = (aqi) => {
    if (aqi == null) return "Unavailable";
    if (aqi <= 20) return "Good";
    if (aqi <= 40) return "Fair";
    if (aqi <= 60) return "Moderate";
    if (aqi <= 80) return "Poor";
    if (aqi <= 100) return "Very poor";
    return "Extremely poor";
  };

  const flagEmoji = (code) => {
    if (!code || code.length !== 2) return "📍";
    try {
      return String.fromCodePoint(...[...code.toUpperCase()].map((c) => 127397 + c.charCodeAt(0)));
    } catch (e) {
      return "📍";
    }
  };

  const countryName = (code) => {
    if (!code) return "";
    try {
      return new Intl.DisplayNames(["en"], { type: "region" }).of(code) || code;
    } catch (e) {
      return code;
    }
  };

  function toast(message) {
    el.toast.textContent = message;
    el.toast.hidden = false;
    requestAnimationFrame(() => el.toast.classList.add("is-visible"));
    clearTimeout(toast._timer);
    toast._timer = setTimeout(() => {
      el.toast.classList.remove("is-visible");
      setTimeout(() => { el.toast.hidden = true; }, 400);
    }, 5200);
  }

  /* ---------------------------------------------------------
     location
     --------------------------------------------------------- */

  function getPosition() {
    return new Promise((resolve, reject) => {
      if (!navigator.geolocation) {
        reject(new Error("Geolocation unsupported"));
        return;
      }
      navigator.geolocation.getCurrentPosition(resolve, reject, {
        enableHighAccuracy: false,
        timeout: 9000,
        maximumAge: 10 * 60 * 1000
      });
    });
  }

  async function permissionState() {
    if (!navigator.permissions || !navigator.permissions.query) return "prompt";
    try {
      const status = await navigator.permissions.query({ name: "geolocation" });
      return status.state;
    } catch (e) {
      return "prompt";
    }
  }

  async function describeCoords(lat, lon) {
    try {
      const url = `https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${lat}&longitude=${lon}&localityLanguage=en`;
      const res = await fetch(url, { headers: { accept: "application/json" } });
      if (res.ok) {
        const d = await res.json();
        const name = d.city || d.locality || d.principalSubdivision;
        if (name) {
          const region = [d.principalSubdivision, countryName(d.countryCode)].filter(Boolean).join(", ");
          return { name, region, lat, lon, source: "gps" };
        }
      }
    } catch (e) { /* fall through */ }

    try {
      const url = `https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${lat}&lon=${lon}&zoom=10&accept-language=en`;
      const res = await fetch(url);
      if (res.ok) {
        const d = await res.json();
        const a = d.address || {};
        const name = a.city || a.town || a.village || a.municipality || a.county || d.name;
        if (name) {
          const region = [a.state, a.country].filter(Boolean).join(", ");
          return { name, region, lat, lon, source: "gps" };
        }
      }
    } catch (e) { /* fall through */ }

    return {
      name: "Current location",
      region: `${Math.abs(lat).toFixed(2)}°${lat >= 0 ? "N" : "S"}, ${Math.abs(lon).toFixed(2)}°${lon >= 0 ? "E" : "W"}`,
      lat,
      lon,
      source: "gps"
    };
  }

  async function ipLocate() {
    try {
      const res = await fetch("https://api.bigdatacloud.net/data/reverse-geocode-client?localityLanguage=en");
      if (res.ok) {
        const d = await res.json();
        if (typeof d.latitude === "number" && typeof d.longitude === "number") {
          return {
            name: d.city || d.locality || d.principalSubdivision || "Approximate location",
            region: [d.principalSubdivision, countryName(d.countryCode)].filter(Boolean).join(", "),
            lat: d.latitude,
            lon: d.longitude,
            source: "ip"
          };
        }
      }
    } catch (e) { /* fall through */ }

    try {
      const res = await fetch("https://ipwho.is/");
      if (res.ok) {
        const d = await res.json();
        if (d && d.success && typeof d.latitude === "number") {
          return {
            name: d.city || d.region || d.country,
            region: [d.region, d.country].filter(Boolean).join(", "),
            lat: d.latitude,
            lon: d.longitude,
            source: "ip"
          };
        }
      }
    } catch (e) { /* fall through */ }

    return null;
  }

  /* ---------------------------------------------------------
     data
     --------------------------------------------------------- */

  async function fetchForecast(lat, lon) {
    const params = new URLSearchParams({
      latitude: lat.toFixed(4),
      longitude: lon.toFixed(4),
      current: [
        "temperature_2m", "relative_humidity_2m", "apparent_temperature", "dew_point_2m",
        "is_day", "precipitation", "weather_code", "cloud_cover", "pressure_msl",
        "wind_speed_10m", "wind_direction_10m", "wind_gusts_10m"
      ].join(","),
      hourly: [
        "temperature_2m", "apparent_temperature", "precipitation_probability",
        "precipitation", "weather_code", "wind_speed_10m", "is_day", "relative_humidity_2m"
      ].join(","),
      daily: [
        "weather_code", "temperature_2m_max", "temperature_2m_min", "apparent_temperature_max",
        "sunrise", "sunset", "uv_index_max", "precipitation_sum",
        "precipitation_probability_max", "wind_speed_10m_max", "wind_direction_10m_dominant"
      ].join(","),
      timezone: "auto",
      forecast_days: "10"
    });
    const res = await fetch(`${ENDPOINTS.forecast}?${params.toString()}`);
    if (!res.ok) throw new Error(`Forecast request failed (${res.status})`);
    return res.json();
  }

  async function fetchAir(lat, lon) {
    const params = new URLSearchParams({
      latitude: lat.toFixed(4),
      longitude: lon.toFixed(4),
      current: "european_aqi,pm2_5,pm10",
      timezone: "auto"
    });
    const res = await fetch(`${ENDPOINTS.air}?${params.toString()}`);
    if (!res.ok) throw new Error("Air quality unavailable");
    return res.json();
  }

  async function loadPlace(place, options) {
    const opts = options || {};
    state.pending = true;
    el.refresh.classList.add("is-busy");
    if (opts.loaderText) el.loaderSub.textContent = opts.loaderText;

    try {
      const data = await fetchForecast(place.lat, place.lon);
      const air = await fetchAir(place.lat, place.lon).catch(() => null);

      state.place = { ...place, timezone: data.timezone || place.timezone };
      state.data = data;
      state.air = air;
      state.lastLoaded = Date.now();
      writeStore(STORE.place, JSON.stringify(state.place));

      render();

      if (opts.initial) {
        setTimeout(() => el.loader.classList.add("is-hidden"), 260);
      }
    } catch (err) {
      console.error(err);
      if (!state.data) {
        state.place = state.place || place;
        renderError();
      } else {
        toast("Couldn't refresh the forecast — showing the last update.");
      }
      if (opts.initial) el.loader.classList.add("is-hidden");
    } finally {
      state.pending = false;
      el.refresh.classList.remove("is-busy");
    }
  }

  /* ---------------------------------------------------------
     boot
     --------------------------------------------------------- */

  async function boot() {
    el.loaderSub.textContent = "Detecting your location…";
    updateUnitButtons();

    const saved = (() => {
      try { return JSON.parse(readStore(STORE.place) || "null"); } catch (e) { return null; }
    })();

    let place = null;
    let notice = null;
    const permission = await permissionState();

    if (permission !== "denied") {
      try {
        el.loaderSub.textContent = "Detecting your location…";
        const pos = await getPosition();
        el.loaderSub.textContent = "Naming your neighbourhood…";
        place = await describeCoords(pos.coords.latitude, pos.coords.longitude);
      } catch (e) { /* permission denied or timed out */ }
    }

    if (!place) {
      el.loaderSub.textContent = "Locating via your network…";
      const ip = await ipLocate();
      if (ip) {
        place = ip;
        notice = "Approximate location from your network. Allow location for street-level precision.";
      }
    }

    if (!place && saved && typeof saved.lat === "number") {
      place = saved;
      notice = "Location access is off — showing your last location.";
    }

    if (!place) {
      place = DEFAULT_PLACE;
      notice = "We couldn't locate you, so here's London.";
    }

    state.notice = notice;
    await loadPlace(place, { initial: true, loaderText: "Fetching the forecast…" });
  }

  /* ---------------------------------------------------------
     rendering
     --------------------------------------------------------- */

  function skyPreset(group, isDay) {
    switch (group) {
      case "clear":
      case "mostly-clear":
        return isDay ? "clear-day" : "clear-night";
      case "partly":
        return isDay ? "partly-day" : "partly-night";
      case "cloudy":
        return isDay ? "cloudy-day" : "cloudy-night";
      case "fog":
        return "fog";
      case "drizzle":
        return "drizzle";
      case "rain":
        return "rain";
      case "showers":
        return isDay ? "showers-day" : "rain";
      case "snow":
        return "snow";
      case "storm":
        return "storm";
      default:
        return isDay ? "partly-day" : "partly-night";
    }
  }

  function applySky(key, isDay) {
    const preset = SKIES[key] || SKIES["partly-day"];
    const a = document.getElementById("skyA");
    const b = document.getElementById("skyB");
    const sky = document.querySelector(".sky");
    if (sky) sky.classList.toggle("is-night", isDay === false);

    if (a && b) {
      const next = state.skyToggle ? a : b;
      const prev = state.skyToggle ? b : a;
      next.style.backgroundImage = preset.bg;
      next.classList.add("is-active");
      prev.classList.remove("is-active");
      state.skyToggle = !state.skyToggle;
    }

    root.style.setProperty("--accent", preset.accent);
    root.style.setProperty("--orb1", preset.orbs[0]);
    root.style.setProperty("--orb2", preset.orbs[1]);
    root.style.setProperty("--orb3", preset.orbs[2]);

    applyWeatherVideo(key);
  }

  /* ---------------------------------------------------------
     live weather footage
     --------------------------------------------------------- */

  function videoAllowed() {
    if (reduceMotion()) return false;
    const connection = navigator.connection;
    if (connection && (connection.saveData || /(^|-)2g$/.test(connection.effectiveType || ""))) return false;
    return true;
  }

  function stopVideo() {
    state.videoToken++;
    [el.videoA, el.videoB].forEach((video) => {
      if (!video) return;
      video.classList.remove("is-active");
      video.pause();
    });
    const sky = document.querySelector(".sky");
    if (sky) sky.classList.remove("has-video");
    state.videoKey = null;
  }

  function applyWeatherVideo(key) {
    const sky = document.querySelector(".sky");
    const source = WEATHER_VIDEOS[key];

    if (!sky || !source || !videoAllowed()) {
      if (state.videoKey) stopVideo();
      return;
    }
    if (state.videoKey === key) return;

    state.videoKey = key;
    const token = ++state.videoToken;
    const useA = !state.videoToggle;
    state.videoToggle = !state.videoToggle;

    const next = useA ? el.videoA : el.videoB;
    const prev = useA ? el.videoB : el.videoA;
    if (!next || !prev) return;

    let started = false;
    const start = () => {
      if (started || token !== state.videoToken) return;
      started = true;

      const reveal = () => {
        if (token !== state.videoToken) return;
        sky.classList.add("has-video");
        next.classList.add("is-active");
        prev.classList.remove("is-active");
        window.setTimeout(() => {
          if (!prev.classList.contains("is-active")) prev.pause();
        }, 1600);
      };

      const playback = next.play();
      if (playback && playback.then) playback.then(reveal).catch(reveal);
      else reveal();
    };

    next.poster = `media/poster-${key}.jpg`;
    next.src = source;
    next.load();
    next.addEventListener("canplay", start, { once: true });
  }

  function nextHours(count) {
    const { hourly, current } = state.data;
    const key = current.time.slice(0, 13);
    let start = hourly.time.findIndex((time) => time.slice(0, 13) === key);
    if (start < 0) start = hourly.time.findIndex((time) => time >= current.time);
    if (start < 0) start = 0;

    const out = [];
    for (let i = 0; i < count && start + i < hourly.time.length; i++) {
      const j = start + i;
      out.push({
        time: hourly.time[j],
        temp: hourly.temperature_2m[j],
        pop: hourly.precipitation_probability ? hourly.precipitation_probability[j] : 0,
        code: hourly.weather_code[j],
        isDay: hourly.is_day[j] === 1
      });
    }
    return out;
  }

  function dailyRows() {
    const d = state.data.daily;
    return d.time.map((time, i) => ({
      time,
      code: d.weather_code[i],
      max: d.temperature_2m_max[i],
      min: d.temperature_2m_min[i],
      pop: d.precipitation_probability_max ? d.precipitation_probability_max[i] : 0,
      sum: d.precipitation_sum ? d.precipitation_sum[i] : 0,
      uv: d.uv_index_max ? d.uv_index_max[i] : null,
      wind: d.wind_speed_10m_max ? d.wind_speed_10m_max[i] : null,
      windDir: d.wind_direction_10m_dominant ? d.wind_direction_10m_dominant[i] : null,
      sunrise: d.sunrise ? d.sunrise[i] : null,
      sunset: d.sunset ? d.sunset[i] : null
    }));
  }

  function chip(icon, label, value) {
    return `<div class="chip">
      <span class="chip-icon">${icon}</span>
      <span class="chip-text"><span class="chip-label">${label}</span><span class="chip-value">${value}</span></span>
    </div>`;
  }

  function renderHero(info, isDay) {
    const { current, daily, timezone } = state.data;
    const place = state.place;
    const today = dailyRows()[0] || {};
    const uv = today.uv;
    const tz = timezone || place.timezone;

    const notice = state.notice
      ? `<span class="notice">${esc(state.notice)}</span>`
      : "";

    el.hero.classList.remove("is-error");
    el.hero.innerHTML = `
      <div class="hero-top">
        <div>
          <div class="place-row">${SVG.pin}<h1 class="place-name">${esc(place.name)}</h1></div>
          <p class="place-region">${esc(place.region || "Local forecast")}</p>
          ${notice}
        </div>
        <div class="hero-clock">
          <p class="hero-time">${esc(localClock(tz))}</p>
          <p class="hero-date">${esc(localDate(tz))}</p>
        </div>
      </div>

      <div class="hero-main">
        <div class="hero-temp">
          <div class="temp-line">
            <span class="temp-value" id="tempValue">${tRaw(current.temperature_2m)}</span>
            <span class="temp-unit">°${state.unit === "f" ? "F" : "C"}</span>
          </div>
          <p class="condition">${esc(info.label)}</p>
          <p class="feels">
            <span>Feels like <b>${t(current.apparent_temperature)}</b></span>
            <span class="dot">·</span>
            <span>H <b>${t(today.max)}</b> &nbsp;L <b>${t(today.min)}</b></span>
          </p>
        </div>
        <div class="hero-visual">
          <div class="hero-glow"></div>
          <div class="hero-icon">${WeatherIcons.svg(current.weather_code, isDay, { detail: true })}</div>
        </div>
      </div>

      <div class="hero-strip">
        ${chip(SVG.thermo, "Feels like", t(current.apparent_temperature))}
        ${chip(SVG.wind, "Wind", `${wind(current.wind_speed_10m)} ${compass(current.wind_direction_10m)}`)}
        ${chip(SVG.humidity, "Humidity", `${Math.round(current.relative_humidity_2m)}%`)}
        ${chip(SVG.sun, "UV index", `${uv == null ? "—" : uv.toFixed(1)} · ${uvLevel(uv)}`)}
        ${chip(SVG.sunrise, "Sunrise", today.sunrise ? timeLabel(today.sunrise) : "—")}
        ${chip(SVG.sunset, "Sunset", today.sunset ? timeLabel(today.sunset) : "—")}
      </div>`;

    animateTemp(Number(tRaw(current.temperature_2m)));
  }

  function animateTemp(target) {
    const node = document.getElementById("tempValue");
    if (!node || Number.isNaN(target)) return;
    if (reduceMotion()) return;
    const from = target - 3;
    const start = performance.now();
    const duration = 850;
    const step = (now) => {
      const progress = Math.min(1, (now - start) / duration);
      const eased = 1 - Math.pow(1 - progress, 3);
      node.textContent = String(Math.round(from + (target - from) * eased));
      if (progress < 1) requestAnimationFrame(step);
      else node.textContent = String(target);
    };
    requestAnimationFrame(step);
  }

  function chartMarkup(hours) {
    if (hours.length < 2) return "";

    const values = hours.map((h) => conv(h.temp));
    const min = Math.min(...values);
    const max = Math.max(...values);
    const span = Math.max(max - min, 1.5);
    const yFor = (v) => 16 + (1 - (v - min) / span) * 62;

    const points = values.map((v, i) => ({
      x: (i / (values.length - 1)) * 100,
      y: yFor(v),
      v
    }));

    let path = `M ${(points[0].x * 10).toFixed(2)} ${points[0].y.toFixed(2)}`;
    for (let i = 1; i < points.length; i++) {
      const p0 = points[i - 1];
      const p1 = points[i];
      const cx = ((p1.x - p0.x) * 10) / 3;
      path += ` C ${(p0.x * 10 + cx).toFixed(2)} ${p0.y.toFixed(2)}, ${(p1.x * 10 - cx).toFixed(2)} ${p1.y.toFixed(2)}, ${(p1.x * 10).toFixed(2)} ${p1.y.toFixed(2)}`;
    }
    const area = `${path} L 1000 104 L 0 104 Z`;

    const labelIdx = [0, 4, 8, 12, 16, 20].filter((i) => i < hours.length && i % 2 === 0) ;
    const idx = labelIdx.length ? labelIdx : [0];

    const temps = idx.map((i) => `<span class="chart-temp ${i === 0 ? "is-first" : ""}" style="left:${points[i].x}%;top:${points[i].y}%">${Math.round(points[i].v)}°</span>`).join("");
    const dots = idx.map((i, k) => `<span class="chart-dot ${k === 0 ? "is-now" : ""}" style="left:${points[i].x}%;top:${points[i].y}%"></span>`).join("");
    const times = idx.map((i) => `<span style="left:${points[i].x}%">${i === 0 ? "Now" : esc(timeLabel(hours[i].time))}</span>`).join("");

    return `<div class="chart">
      <div class="chart-layer">
        ${temps}
        <svg class="chart-svg" viewBox="0 0 1000 104" preserveAspectRatio="none" aria-hidden="true">
          <defs>
            <linearGradient id="chartFill" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stop-color="var(--accent)" stop-opacity="0.42" />
              <stop offset="100%" stop-color="var(--accent)" stop-opacity="0" />
            </linearGradient>
          </defs>
          <path d="${area}" fill="url(#chartFill)" />
          <path class="chart-line" d="${path}" fill="none" stroke="var(--accent)" stroke-width="2.4"
                stroke-linecap="round" stroke-linejoin="round" vector-effect="non-scaling-stroke" />
        </svg>
        ${dots}
      </div>
      <div class="chart-times">${times}</div>
    </div>`;
  }

  function renderHourly() {
    const hours = nextHours(24);
    const subs = hours.length ? `${timeLabel(hours[0].time)} → ${timeLabel(hours[hours.length - 1].time)}` : "";
    el.hourlySub.textContent = subs;

    const cards = hours
      .map((h, i) => {
        const dry = (h.pop || 0) < 10;
        return `<div class="hour ${i === 0 ? "is-now" : ""}" style="--i:${i}">
          <span class="hour-time">${i === 0 ? "Now" : esc(timeLabel(h.time))}</span>
          ${WeatherIcons.svg(h.code, h.isDay)}
          <span class="hour-temp">${t(h.temp)}</span>
          <span class="hour-pop ${dry ? "is-dry" : ""}">${SVG.drop}${Math.round(h.pop || 0)}%</span>
        </div>`;
      })
      .join("");

    el.hourly.innerHTML = `${chartMarkup(hours)}<div class="hour-scroll">${cards}</div>`;
  }

  function renderDaily() {
    const days = dailyRows();
    const weekMin = Math.min(...days.map((d) => d.min));
    const weekMax = Math.max(...days.map((d) => d.max));
    const range = Math.max(weekMax - weekMin, 1);

    el.daily.innerHTML = `<div class="day-list">${days
      .map((d, i) => {
        const left = ((d.min - weekMin) / range) * 100;
        const width = ((d.max - d.min) / range) * 100;
        const dry = (d.pop || 0) < 10;
        const details = [
          ["Rain chance", `${Math.round(d.pop || 0)}%`],
          ["Rain total", precip(d.sum)],
          ["UV index", d.uv == null ? "—" : `${d.uv.toFixed(1)} · ${uvLevel(d.uv)}`],
          ["Max wind", `${wind(d.wind)} ${compass(d.windDir)}`],
          ["Sunrise", d.sunrise ? timeLabel(d.sunrise) : "—"],
          ["Sunset", d.sunset ? timeLabel(d.sunset) : "—"]
        ]
          .map(
            ([label, value]) =>
              `<div class="detail-item"><span class="detail-label">${label}</span><span class="detail-value">${esc(value)}</span></div>`
          )
          .join("");

        return `<div class="day ${i === 0 ? "is-today" : ""}" style="--i:${i}">
          <button class="day-row" type="button" aria-expanded="false" aria-label="${i === 0 ? "Today" : weekday(d.time)}, ${esc(WeatherIcons.label(d.code))}, high ${t(d.max)}, low ${t(d.min)}. Show details">
            <span class="day-name">${i === 0 ? "Today" : weekday(d.time)}<span class="day-date"> ${dayMonth(d.time)}</span></span>
            <span class="day-icon">${WeatherIcons.svg(d.code, true)}</span>
            <span class="day-precip ${dry ? "is-dry" : ""}">${SVG.drop}${Math.round(d.pop || 0)}%</span>
            <span class="day-bar"><span class="bar-track"><span class="bar-fill" style="left:${left}%;width:${Math.max(width, 4)}%"></span></span></span>
            <span class="day-temps"><b>${t(d.max)}</b><span>${t(d.min)}</span></span>
            <span class="day-chev">${SVG.chevron}</span>
          </button>
          <div class="day-details"><div><div class="detail-grid">${details}</div></div></div>
        </div>`;
      })
      .join("")}</div>`;
  }

  function renderTiles() {
    const { current, daily } = state.data;
    const today = dailyRows()[0] || {};
    const air = state.air && state.air.current ? state.air.current : null;
    const aqi = air ? air.european_aqi : null;

    const items = [
      {
        icon: SVG.thermo,
        label: "Feels like",
        value: t(current.apparent_temperature),
        note: `Actual ${t(current.temperature_2m)} · dew point ${t(current.dew_point_2m)}`
      },
      {
        icon: SVG.humidity,
        label: "Humidity",
        value: `${Math.round(current.relative_humidity_2m)}<small>%</small>`,
        note: current.relative_humidity_2m > 75 ? "Muggy air" : current.relative_humidity_2m < 35 ? "Dry air" : "Comfortable"
      },
      {
        icon: SVG.wind,
        label: "Wind",
        value: wind(current.wind_speed_10m),
        note: `${compass(current.wind_direction_10m)} · gusts ${wind(current.wind_gusts_10m)}`
      },
      {
        icon: SVG.sun,
        label: "UV index",
        value: today.uv == null ? "—" : today.uv.toFixed(1),
        note: `${uvLevel(today.uv)} — ${today.uv >= 6 ? "sun protection advised" : "no protection needed"}`
      },
      {
        icon: SVG.raincloud,
        label: "Precipitation",
        value: precip(today.sum),
        note: `${Math.round(today.pop || 0)}% chance today`
      },
      {
        icon: SVG.gauge,
        label: "Pressure",
        value: `${Math.round(current.pressure_msl)}<small>hPa</small>`,
        note: current.pressure_msl > 1020 ? "High — settled" : current.pressure_msl < 1000 ? "Low — unsettled" : "Steady"
      },
      {
        icon: SVG.leaf,
        label: "Air quality",
        value: aqi == null ? "—" : `${Math.round(aqi)}<small>EAQI</small>`,
        note: air ? `${aqiBand(aqi)} · PM2.5 ${air.pm2_5 == null ? "—" : air.pm2_5.toFixed(0)} µg/m³` : "Not available here"
      },
      {
        icon: SVG.cloud,
        label: "Cloud cover",
        value: `${Math.round(current.cloud_cover)}<small>%</small>`,
        note: current.cloud_cover > 80 ? "Almost fully overcast" : current.cloud_cover > 40 ? "Broken cloud" : "Mostly clear"
      }
    ];

    el.tiles.innerHTML = items
      .map(
        (item, i) => `<article class="tile glass" style="--i:${i}">
          <div class="tile-head">${item.icon}<span>${item.label}</span></div>
          <div class="tile-value">${item.value}</div>
          <div class="tile-note">${esc(item.note)}</div>
        </article>`
      )
      .join("");
  }

  function render() {
    if (!state.data || !state.place) return;
    const current = state.data.current;
    const info = WeatherIcons.codeInfo(current.weather_code);
    const isDay = current.is_day !== 0;

    applySky(skyPreset(info.group, isDay), isDay);
    renderHero(info, isDay);
    renderHourly();
    renderDaily();
    renderTiles();

    document.title = `${tRaw(current.temperature_2m)}° · ${state.place.name} — Aura`;
    el.updated.textContent = `Updated ${new Date().toLocaleTimeString("en-GB", { hour: "numeric", minute: "2-digit", hour12: true })}`;
  }

  function renderError() {
    const name = state.place ? state.place.name : "your location";
    el.hero.classList.add("is-error");
    el.hero.innerHTML = `<div class="hero-error">
      <h2>The sky went quiet</h2>
      <p>We couldn't load a forecast for ${esc(name)}. Check your connection, then try again.</p>
      <button class="btn-ghost" type="button" id="retryBtn">Try again</button>
    </div>`;
    const retry = document.getElementById("retryBtn");
    if (retry) retry.addEventListener("click", () => loadPlace(state.place || DEFAULT_PLACE, { initial: true }));
    el.updated.textContent = "Offline";
  }

  /* ---------------------------------------------------------
     units
     --------------------------------------------------------- */

  function updateUnitButtons() {
    document.querySelectorAll(".unit-btn").forEach((btn) => {
      const active = btn.dataset.unit === state.unit;
      btn.classList.toggle("is-active", active);
      btn.setAttribute("aria-pressed", String(active));
    });
  }

  function setUnit(unit) {
    if (unit === state.unit) return;
    state.unit = unit;
    writeStore(STORE.unit, unit);
    updateUnitButtons();
    if (state.data) render();
  }

  document.querySelectorAll(".unit-btn").forEach((btn) => {
    btn.addEventListener("click", () => setUnit(btn.dataset.unit === "f" ? "f" : "c"));
  });

  /* ---------------------------------------------------------
     search
     --------------------------------------------------------- */

  let searchTimer = null;

  function closeResults() {
    el.results.hidden = true;
    el.results.innerHTML = "";
    el.search.setAttribute("aria-expanded", "false");
    state.results = [];
    state.activeResult = -1;
  }

  function openResults(markup) {
    el.results.innerHTML = markup;
    el.results.hidden = false;
    el.search.setAttribute("aria-expanded", "true");
  }

  async function runSearch(query) {
    try {
      const params = new URLSearchParams({ name: query, count: "6", language: "en", format: "json" });
      const res = await fetch(`${ENDPOINTS.geocode}?${params.toString()}`);
      if (!res.ok) throw new Error("Search failed");
      const data = await res.json();
      if (el.search.value.trim() !== query) return;

      state.results = Array.isArray(data.results) ? data.results : [];
      state.activeResult = -1;

      if (!state.results.length) {
        openResults(`<p class="result-empty">No places match “${esc(query)}”.</p>`);
        return;
      }

      openResults(
        state.results
          .map(
            (place, i) => `<button class="result" type="button" role="option" data-index="${i}">
              <span class="result-flag">${flagEmoji(place.country_code)}</span>
              <span class="result-body">
                <span class="result-name">${esc(place.name)}</span>
                <span class="result-region">${esc([place.admin1, place.country].filter(Boolean).join(", "))}</span>
              </span>
            </button>`
          )
          .join("")
      );
    } catch (e) {
      openResults(`<p class="result-empty">Search is unavailable right now.</p>`);
    }
  }

  el.search.addEventListener("input", () => {
    const query = el.search.value.trim();
    clearTimeout(searchTimer);
    if (query.length < 2) {
      closeResults();
      return;
    }
    searchTimer = setTimeout(() => runSearch(query), 240);
  });

  el.search.addEventListener("keydown", (event) => {
    if (el.results.hidden) return;
    const items = Array.from(el.results.querySelectorAll(".result"));
    if (!items.length) return;

    if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      event.preventDefault();
      const delta = event.key === "ArrowDown" ? 1 : -1;
      state.activeResult = (state.activeResult + delta + items.length) % items.length;
      items.forEach((item, i) => item.classList.toggle("is-active", i === state.activeResult));
      items[state.activeResult].scrollIntoView({ block: "nearest" });
    } else if (event.key === "Enter") {
      event.preventDefault();
      const index = state.activeResult >= 0 ? state.activeResult : 0;
      items[index].click();
    } else if (event.key === "Escape") {
      closeResults();
      el.search.blur();
    }
  });

  el.results.addEventListener("click", (event) => {
    const button = event.target.closest(".result");
    if (!button) return;
    const place = state.results[Number(button.dataset.index)];
    if (!place) return;

    state.notice = null;
    closeResults();
    el.search.value = "";
    el.search.blur();

    loadPlace({
      name: place.name,
      region: [place.admin1, place.country].filter(Boolean).join(", "),
      lat: place.latitude,
      lon: place.longitude,
      timezone: place.timezone
    });
  });

  document.addEventListener("click", (event) => {
    if (!event.target.closest(".search")) closeResults();
  });

  el.search.addEventListener("focus", () => {
    if (state.results.length) el.search.setAttribute("aria-expanded", "true");
  });

  /* ---------------------------------------------------------
     daily expand/collapse
     --------------------------------------------------------- */

  el.daily.addEventListener("click", (event) => {
    const button = event.target.closest(".day-row");
    if (!button) return;
    const day = button.closest(".day");
    const open = day.classList.toggle("is-open");
    button.setAttribute("aria-expanded", String(open));
  });

  /* ---------------------------------------------------------
     actions
     --------------------------------------------------------- */

  el.refresh.addEventListener("click", () => {
    if (state.pending) return;
    loadPlace(state.place || DEFAULT_PLACE);
  });

  el.locate.addEventListener("click", async () => {
    if (state.pending) return;
    el.locate.classList.add("is-busy");
    try {
      const pos = await getPosition();
      const place = await describeCoords(pos.coords.latitude, pos.coords.longitude);
      state.notice = null;
      await loadPlace(place);
    } catch (e) {
      toast("Location permission is off. Search for a city instead.");
    } finally {
      el.locate.classList.remove("is-busy");
    }
  });

  document.addEventListener("visibilitychange", () => {
    if (document.hidden || !state.place || state.pending) return;
    if (Date.now() - state.lastLoaded > 10 * 60 * 1000) {
      loadPlace(state.place);
    }
  });

  setInterval(() => {
    if (document.hidden || !state.place || state.pending) return;
    loadPlace(state.place);
  }, 10 * 60 * 1000);

  boot();
})();
