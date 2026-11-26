/* Layered, lit weather glyphs rendered as SVG.
   Each icon gets unique gradient ids so many can share a page. */
(function () {
  "use strict";

  let seq = 0;

  /* Soft cumulus silhouette: two lit crowns and a flat shaded base. */
  const CLOUD =
    "M24 68C17.9 68 13 63.1 13 57C13 51.4 17.2 46.8 22.7 46.1C24.4 33.9 34.8 24.5 47.5 24.5C59.2 24.5 69 32.6 71.7 43.5C77.8 44.8 82.5 50.3 82.5 57C82.5 63.1 77.6 68 71.5 68Z";

  const CODES = {
    0: ["Clear sky", "clear"],
    1: ["Mainly clear", "mostly-clear"],
    2: ["Partly cloudy", "partly"],
    3: ["Overcast", "cloudy"],
    45: ["Fog", "fog"],
    48: ["Freezing fog", "fog"],
    51: ["Light drizzle", "drizzle"],
    53: ["Drizzle", "drizzle"],
    55: ["Heavy drizzle", "drizzle"],
    56: ["Freezing drizzle", "drizzle"],
    57: ["Freezing drizzle", "drizzle"],
    61: ["Light rain", "rain"],
    63: ["Rain", "rain"],
    65: ["Heavy rain", "rain"],
    66: ["Freezing rain", "rain"],
    67: ["Freezing rain", "rain"],
    71: ["Light snow", "snow"],
    73: ["Snow", "snow"],
    75: ["Heavy snow", "snow"],
    77: ["Snow grains", "snow"],
    80: ["Light showers", "showers"],
    81: ["Showers", "showers"],
    82: ["Heavy showers", "showers"],
    85: ["Snow showers", "snow"],
    86: ["Heavy snow showers", "snow"],
    95: ["Thunderstorm", "storm"],
    96: ["Thunderstorm, hail", "storm"],
    99: ["Severe thunderstorm", "storm"]
  };

  function defs(u, night) {
    const light = night
      ? ["#e8eff9", "#cbd8e9", "#9cafc8", "#798ca7"]
      : ["#ffffff", "#f8fbff", "#dbe8f7", "#b3c8dd"];

    return `<defs>
      <radialGradient id="sun-${u}" cx="36%" cy="30%" r="72%">
        <stop offset="0%" stop-color="#fffef4"/>
        <stop offset="26%" stop-color="#fff7cc"/>
        <stop offset="60%" stop-color="#ffd45e"/>
        <stop offset="100%" stop-color="#eea127"/>
      </radialGradient>
      <radialGradient id="sunHalo-${u}" cx="50%" cy="50%" r="50%">
        <stop offset="0%" stop-color="#ffeeb0" stop-opacity=".8"/>
        <stop offset="36%" stop-color="#ffd268" stop-opacity=".3"/>
        <stop offset="100%" stop-color="#ffc44d" stop-opacity="0"/>
      </radialGradient>
      <linearGradient id="cloud-${u}" x1="24%" y1="0%" x2="62%" y2="100%">
        <stop offset="0%" stop-color="${light[0]}"/>
        <stop offset="36%" stop-color="${light[1]}"/>
        <stop offset="68%" stop-color="${light[2]}"/>
        <stop offset="100%" stop-color="${light[3]}"/>
      </linearGradient>
      <linearGradient id="cloudBack-${u}" x1="0%" y1="0%" x2="45%" y2="100%">
        <stop offset="0%" stop-color="${night ? "#a9b9cf" : "#d9e5f3"}"/>
        <stop offset="100%" stop-color="${night ? "#667892" : "#8da2bc"}"/>
      </linearGradient>
      <radialGradient id="moon-${u}" cx="34%" cy="28%" r="76%">
        <stop offset="0%" stop-color="#ffffff"/>
        <stop offset="45%" stop-color="#f7f9ff"/>
        <stop offset="82%" stop-color="#d8dfef"/>
        <stop offset="100%" stop-color="#b8c1d8"/>
      </radialGradient>
      <radialGradient id="moonGlow-${u}" cx="50%" cy="50%" r="50%">
        <stop offset="0%" stop-color="#e2e9ff" stop-opacity=".5"/>
        <stop offset="50%" stop-color="#b6c3ff" stop-opacity=".16"/>
        <stop offset="100%" stop-color="#a4b4ff" stop-opacity="0"/>
      </radialGradient>
      <linearGradient id="rain-${u}" gradientUnits="userSpaceOnUse" x1="0" y1="66" x2="0" y2="92">
        <stop offset="0%" stop-color="#cdefff" stop-opacity="0"/>
        <stop offset="24%" stop-color="#cdefff" stop-opacity=".95"/>
        <stop offset="100%" stop-color="#6fb9e6" stop-opacity=".08"/>
      </linearGradient>
      <linearGradient id="bolt-${u}" x1="0%" y1="0%" x2="30%" y2="100%">
        <stop offset="0%" stop-color="#fffdf0"/>
        <stop offset="50%" stop-color="#ffdd72"/>
        <stop offset="100%" stop-color="#ffb32a"/>
      </linearGradient>
      <linearGradient id="fog-${u}" gradientUnits="userSpaceOnUse" x1="8" y1="0" x2="88" y2="0">
        <stop offset="0%" stop-color="#ffffff" stop-opacity="0"/>
        <stop offset="22%" stop-color="#ffffff" stop-opacity=".78"/>
        <stop offset="78%" stop-color="#ffffff" stop-opacity=".62"/>
        <stop offset="100%" stop-color="#ffffff" stop-opacity="0"/>
      </linearGradient>
      <clipPath id="cloudClip-${u}"><path d="${CLOUD}"/></clipPath>
      <filter id="soft-${u}" x="-40%" y="-40%" width="180%" height="180%">
        <feGaussianBlur stdDeviation="2.6"/>
      </filter>
      <filter id="glow-${u}" x="-80%" y="-80%" width="260%" height="260%">
        <feGaussianBlur stdDeviation="2.4" result="b"/>
        <feMerge><feMergeNode in="b"/><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge>
      </filter>
    </defs>`;
  }

  function cloud(u, opts) {
    const o = opts || {};
    const x = o.x || 0;
    const y = o.y || 0;
    const night = !!o.night;
    const detail = !!o.detail;
    const dark = !!o.dark;
    const scale = o.scale == null ? 1 : o.scale;
    const opacity = o.opacity == null ? 1 : o.opacity;
    const soft = detail ? `filter="url(#soft-${u})"` : "";

    return `<g transform="translate(${x} ${y})" opacity="${opacity}">
      <g class="cloud-group">
        <g transform="translate(48 46) scale(${scale}) translate(-48 -46)">
          <path d="${CLOUD}" fill="url(#cloud-${u})"/>
          ${dark ? `<path d="${CLOUD}" fill="#33415a" opacity=".36"/>` : ""}
          <g clip-path="url(#cloudClip-${u})">
            <ellipse cx="36" cy="31" rx="20" ry="9.4" fill="#ffffff" opacity="${night ? (dark ? 0.08 : 0.16) : 0.72}" transform="rotate(-13 36 31)" ${soft}/>
            <ellipse cx="58" cy="39" rx="11" ry="6" fill="#ffffff" opacity="${night ? 0.07 : 0.28}" ${soft}/>
            <ellipse cx="47" cy="70" rx="34" ry="13" fill="${night ? "#2c3b53" : "#6d87a4"}" opacity="${night ? 0.55 : 0.36}" ${soft}/>
            <ellipse cx="19" cy="60" rx="11" ry="11" fill="${night ? "#4a5c76" : "#93a9c2"}" opacity=".28" ${soft}/>
          </g>
          <path d="${CLOUD}" fill="none" stroke="#ffffff" stroke-opacity="${night ? 0.14 : 0.3}" stroke-width="0.7"/>
        </g>
      </g>
    </g>`;
  }

  function backCloud(u, x, y) {
    return `<g transform="translate(${x || 0} ${y || 0})">
      <g class="cloud-rear" opacity=".9">
        <path d="${CLOUD}" fill="url(#cloudBack-${u})"
              transform="translate(48 46) scale(.88) translate(-48 -46)"/>
      </g>
    </g>`;
  }

  function sun(u, x, y, r, detail) {
    let rays = "";
    for (let i = 0; i < 12; i++) {
      const a = (i * Math.PI) / 6;
      const outer = r * (i % 2 ? 1.6 : 1.9);
      rays += `<line x1="${(x + Math.cos(a) * r * 1.16).toFixed(1)}" y1="${(y + Math.sin(a) * r * 1.16).toFixed(1)}" x2="${(x + Math.cos(a) * outer).toFixed(1)}" y2="${(y + Math.sin(a) * outer).toFixed(1)}" stroke="#ffd97a" stroke-opacity="${i % 2 ? 0.42 : 0.66}" stroke-width="${i % 2 ? 1.3 : 2}" stroke-linecap="round"/>`;
    }
    const soft = detail ? `filter="url(#soft-${u})"` : "";
    return `<g class="sun-rays">${rays}</g>
      <circle class="halo" cx="${x}" cy="${y}" r="${r * 2.3}" fill="url(#sunHalo-${u})"/>
      <circle cx="${x}" cy="${y}" r="${r * 1.14}" fill="#ffebad" opacity=".4" ${soft}/>
      <circle cx="${x}" cy="${y}" r="${r}" fill="url(#sun-${u})"/>
      <ellipse cx="${x - r * 0.26}" cy="${y - r * 0.32}" rx="${r * 0.52}" ry="${r * 0.4}" fill="#fffdf0" opacity=".5" ${soft}/>`;
  }

  function moon(u, x, y, r, detail) {
    const soft = detail ? `filter="url(#soft-${u})"` : "";
    return `<circle class="halo" cx="${x}" cy="${y}" r="${r * 1.8}" fill="url(#moonGlow-${u})"/>
      <circle cx="${x}" cy="${y}" r="${r}" fill="url(#moon-${u})"/>
      <g opacity=".5">
        <ellipse cx="${x - r * 0.32}" cy="${y - r * 0.3}" rx="${r * 0.26}" ry="${r * 0.22}" fill="#a9b2cb" ${soft}/>
        <ellipse cx="${x + r * 0.3}" cy="${y + r * 0.28}" rx="${r * 0.2}" ry="${r * 0.16}" fill="#b3bbd2" opacity=".8" ${soft}/>
        <ellipse cx="${x - r * 0.08}" cy="${y + r * 0.48}" rx="${r * 0.12}" ry="${r * 0.09}" fill="#b3bbd2" opacity=".7" ${soft}/>
        <ellipse cx="${x + r * 0.42}" cy="${y - r * 0.42}" rx="${r * 0.11}" ry="${r * 0.08}" fill="#c5cce0" opacity=".8" ${soft}/>
      </g>
      <path d="M ${x - r * 0.9} ${y - r * 0.42} A ${r} ${r} 0 0 1 ${x - r * 0.18} ${y - r * 0.98}"
            fill="none" stroke="#ffffff" stroke-opacity=".38" stroke-width="1"/>`;
  }

  function stars() {
    return `<g class="stars">
      <circle class="star s1" cx="16" cy="22" r="1.5" fill="#fff"/>
      <circle class="star s2" cx="29" cy="12" r="1.1" fill="#fff"/>
      <circle class="star s3" cx="79" cy="20" r="1.3" fill="#fff"/>
      <circle class="star s4" cx="87" cy="39" r="1" fill="#fff"/>
      <circle class="star s5" cx="12" cy="45" r="1.1" fill="#fff"/>
      <circle class="star s6" cx="67" cy="10" r="1.2" fill="#fff"/>
      <path class="star s3" d="M74 55l1 2.6 2.6 1-2.6 1-1 2.6-1-2.6-2.6-1 2.6-1Z" fill="#fff" opacity=".85"/>
    </g>`;
  }

  function rain(u, list) {
    return `<g class="rain">${list
      .map(
        ([x1, y1, x2, y2], i) =>
          `<line class="drop d${(i % 3) + 1}" x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="url(#rain-${u})" stroke-width="${i % 2 ? 2 : 2.5}" stroke-linecap="round"/>`
      )
      .join("")}</g>`;
  }

  function splashes(list) {
    return `<g class="splashes">${list
      .map(
        ([cx, cy], i) =>
          `<ellipse class="splash p${i + 1}" cx="${cx}" cy="${cy}" rx="4" ry="1.1" fill="none" stroke="#cdefff" stroke-opacity=".4" stroke-width="1"/>`
      )
      .join("")}</g>`;
  }

  function flake(x, y, r, cls) {
    let arms = "";
    for (let i = 0; i < 6; i++) {
      arms += `<g transform="rotate(${i * 60})">
        <path d="M0 ${-r}V${r}" fill="none" stroke="#ffffff" stroke-width="1.15" stroke-linecap="round"/>
        <path d="M0 ${-r * 0.62}l${r * 0.3} ${r * 0.3}M0 ${-r * 0.62}l${-r * 0.3} ${r * 0.3}" fill="none" stroke="#ffffff" stroke-width="1.1" stroke-linecap="round"/>
        <path d="M0 ${r * 0.62}l${r * 0.3} ${-r * 0.3}M0 ${r * 0.62}l${-r * 0.3} ${-r * 0.3}" fill="none" stroke="#ffffff" stroke-width="1.1" stroke-linecap="round"/>
      </g>`;
    }
    return `<g transform="translate(${x} ${y})"><g class="flake ${cls || ""}">${arms}</g></g>`;
  }

  function fogBands(u, detail) {
    const soft = detail ? `filter="url(#soft-${u})"` : "";
    return [
      ["M10 52c12-5 23 3 36 1s21-6 38-2", 4.2, 1, 0.4],
      ["M5 61c14-6 27 4 41 1s22-6 42-1", 4.8, 2, 0.5],
      ["M15 70c11-4 22 3 33 0s19-4 30-1", 3.6, 3, 0.36]
    ]
      .map(
        ([d, w, i, o]) =>
          `<path class="fog-band b${i}" d="${d}" fill="none" stroke="url(#fog-${u})" stroke-width="${w}" stroke-linecap="round" opacity="${o}" ${soft}/>`
      )
      .join("");
  }

  function bolt(u, detail) {
    return `<g class="bolt-group" ${detail ? `filter="url(#glow-${u})"` : ""}>
      <path class="bolt" d="M52 62 L38 82 h8.5 l-3.5 11 15-18 h-8.5 l5-13 Z" fill="url(#bolt-${u})"/>
      <path class="bolt-branch" d="M45 76.5l-7 4M56 72l8 3.5" fill="none" stroke="#ffe9a8" stroke-width="1.4" stroke-linecap="round" opacity=".6"/>
    </g>`;
  }

  const shapes = {
    "clear-day": (u, d) => sun(u, 48, 46, 18, d),
    "clear-night": (u, d) => stars() + moon(u, 49, 45, 19, d),

    "partly-day": (u, d) => sun(u, 33, 30, 11.5, d) + backCloud(u, 6, 12) + cloud(u, { x: 4, y: 9, detail: d }),
    "partly-night": (u, d, n) =>
      stars() + moon(u, 32, 28, 11.5, d) + backCloud(u, 6, 12) + cloud(u, { x: 4, y: 9, night: n, detail: d }),

    cloudy: (u, d, n) =>
      cloud(u, { x: -11, y: -7, night: n, detail: d, opacity: 0.5, scale: 0.82 }) +
      cloud(u, { x: 6, y: 8, night: n, detail: d }),
    overcast: (u, d, n) =>
      cloud(u, { x: -13, y: -11, night: n, detail: d, opacity: 0.55, scale: 0.85 }) +
      cloud(u, { x: 13, y: -2, night: n, detail: d, opacity: 0.7, scale: 0.95 }) +
      cloud(u, { x: -1, y: 10, night: n, detail: d }),
    fog: (u, d, n) =>
      cloud(u, { x: 2, y: -10, night: n, detail: d, opacity: 0.72, scale: 0.9 }) + fogBands(u, d),

    drizzle: (u, d, n) =>
      cloud(u, { x: 0, y: -6, night: n, detail: d }) +
      rain(u, [[35, 72, 32, 81], [47, 73, 44, 82], [59, 72, 56, 80]]) +
      splashes([[32, 85], [56, 85]]),
    rain: (u, d, n) =>
      cloud(u, { x: 0, y: -6, night: n, detail: d }) +
      rain(u, [[26, 70, 22, 85], [36, 72, 32, 87], [46, 70, 42, 86], [56, 73, 52, 88], [66, 71, 62, 85]]) +
      splashes([[21, 89], [42, 90], [61, 88]]),
    showers: (u, d, n) =>
      sun(u, 27, 23, 10.5, d) +
      backCloud(u, 16, 12) +
      cloud(u, { x: 9, y: 8, night: n, detail: d }) +
      rain(u, [[38, 73, 35, 84], [49, 74, 46, 86], [60, 73, 57, 84]]),
    snow: (u, d, n) =>
      cloud(u, { x: 0, y: -7, night: n, detail: d }) +
      flake(25, 77, 5, "f1") +
      flake(39, 87, 4.2, "f2") +
      flake(53, 76, 5.5, "f3") +
      flake(67, 84, 3.6, "f4") +
      flake(33, 67, 3, "f5") +
      flake(60, 92, 2.6, "f6"),
    storm: (u, d) =>
      cloud(u, { x: -8, y: -12, night: true, dark: true, detail: d, opacity: 0.6, scale: 0.85 }) +
      cloud(u, { x: 2, y: -2, night: true, dark: true, detail: d }) +
      bolt(u, d) +
      rain(u, [[25, 72, 22, 84], [72, 72, 69, 83]])
  };

  function codeInfo(code) {
    const entry = CODES[code];
    return entry ? { label: entry[0], group: entry[1] } : { label: "Unknown", group: "cloudy" };
  }

  function shapeKey(group, isDay) {
    if (group === "clear" || group === "mostly-clear") return isDay ? "clear-day" : "clear-night";
    if (group === "partly") return isDay ? "partly-day" : "partly-night";
    return group;
  }

  function svg(code, isDay, options) {
    const opts = options || {};
    const info = codeInfo(code);
    const key = shapeKey(info.group, isDay);
    const build = shapes[key] || shapes.cloudy;
    const u = `w${++seq}`;
    const night = /night/.test(key);

    return `<svg class="wi ${opts.cls || ""}" viewBox="0 0 96 96" role="img" aria-label="${info.label}">${defs(
      u,
      night
    )}${build(u, opts.detail === true, night)}</svg>`;
  }

  window.WeatherIcons = {
    svg,
    codeInfo,
    group: (code) => codeInfo(code).group,
    label: (code) => codeInfo(code).label
  };
})();
