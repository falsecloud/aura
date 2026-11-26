.pragma library

function imperial(units) {
    return units === "imperial";
}

function temp(value, units) {
    if (value === null || value === undefined || isNaN(value)) return "--";
    var v = imperial(units) ? value * 9 / 5 + 32 : value;
    return Math.round(v);
}

function tempUnit(units) {
    return imperial(units) ? "°F" : "°C";
}

function speed(value, units) {
    if (value === null || value === undefined || isNaN(value)) return "--";
    var v = imperial(units) ? value * 0.621371 : value;
    return Math.round(v);
}

function speedUnit(units) {
    return imperial(units) ? "mph" : "km/h";
}

function precip(value, units) {
    if (value === null || value === undefined || isNaN(value)) return "0";
    var v = imperial(units) ? value / 25.4 : value;
    if (v > 0 && v < 0.01) return "<0.01";
    return imperial(units) ? v.toFixed(2) : v.toFixed(1);
}

function precipUnit(units) {
    return imperial(units) ? "in" : "mm";
}

function pressure(value, units) {
    if (!value) return "--";
    return imperial(units) ? (value * 0.02953).toFixed(2) : Math.round(value);
}

function pressureUnit(units) {
    return imperial(units) ? "inHg" : "hPa";
}

function visibility(value, units) {
    if (value === null || value === undefined) return "--";
    var v = imperial(units) ? value * 0.621371 : value / 1000;
    return v.toFixed(v < 10 ? 1 : 0);
}

function visibilityUnit(units) {
    return imperial(units) ? "mi" : "km";
}

function timeLabel(iso) {
    if (!iso) return "--";
    var i = iso.indexOf("T");
    return i >= 0 ? iso.substring(i + 1, i + 6) : iso;
}

function hourLabel(iso) {
    if (!iso) return "--";
    var h = parseInt(timeLabel(iso).substring(0, 2), 10);
    if (isNaN(h)) return "--";
    var suffix = h >= 12 ? "PM" : "AM";
    var hh = h % 12;
    if (hh === 0) hh = 12;
    return hh + " " + suffix;
}

function dayLabel(date) {
    if (!date) return "--";
    var d = new Date(date + "T12:00:00Z");
    return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][d.getUTCDay()];
}

function longDay(date) {
    if (!date) return "--";
    var d = new Date(date + "T12:00:00Z");
    return ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][d.getUTCDay()];
}

function dateLabel(date) {
    if (!date) return "";
    var d = new Date(date + "T12:00:00Z");
    var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[d.getUTCMonth()] + " " + d.getUTCDate();
}

function relativeDay(date, index) {
    if (index === 0) return "Today";
    if (index === 1) return "Tomorrow";
    return dayLabel(date);
}

function compass(deg) {
    var dirs = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"];
    var i = Math.round(((deg || 0) % 360) / 22.5) % 16;
    return dirs[i];
}

function uvLabel(uv) {
    if (uv === null || uv === undefined) return "—";
    if (uv < 3) return "Low";
    if (uv < 6) return "Moderate";
    if (uv < 8) return "High";
    if (uv < 11) return "Very high";
    return "Extreme";
}

function uvColor(uv) {
    if (uv < 3) return "#77e3a1";
    if (uv < 6) return "#ffd166";
    if (uv < 8) return "#ff9f5a";
    if (uv < 11) return "#ff6b6b";
    return "#c792ff";
}

function aqiLabel(aqi) {
    if (aqi === null || aqi === undefined) return "—";
    if (aqi <= 20) return "Good";
    if (aqi <= 40) return "Fair";
    if (aqi <= 60) return "Moderate";
    if (aqi <= 80) return "Poor";
    if (aqi <= 100) return "Very poor";
    return "Extremely poor";
}

function aqiColor(aqi) {
    if (aqi === null || aqi === undefined) return "#9fb0c7";
    if (aqi <= 20) return "#77e3a1";
    if (aqi <= 40) return "#c8e37a";
    if (aqi <= 60) return "#ffd166";
    if (aqi <= 80) return "#ff9f5a";
    if (aqi <= 100) return "#ff6b6b";
    return "#c792ff";
}

function aqiPercent(aqi) {
    if (!aqi) return 0;
    return Math.max(3, Math.min(100, aqi));
}

function clock(iso) {
    var t = timeLabel(iso);
    if (t === "--") return t;
    var h = parseInt(t.substring(0, 2), 10);
    var m = t.substring(3, 5);
    var suffix = h >= 12 ? "PM" : "AM";
    var hh = h % 12;
    if (hh === 0) hh = 12;
    return hh + ":" + m + " " + suffix;
}

function clamp(value, lo, hi) {
    return Math.max(lo, Math.min(hi, value));
}

function weatherIcon(code, isDay) {
    if (code === 0) return isDay ? "clear-day" : "clear-night";
    if (code === 1 || code === 2) return isDay ? "partly-day" : "partly-night";
    if (code === 3) return "cloudy";
    if (code === 45 || code === 48) return "fog";
    if (code >= 51 && code <= 57) return "drizzle";
    if (code >= 61 && code <= 67) return "rain";
    if (code >= 71 && code <= 77) return "snow";
    if (code >= 80 && code <= 82) return "showers";
    if (code === 85 || code === 86) return "snow";
    if (code >= 95) return "storm";
    return "cloudy";
}
