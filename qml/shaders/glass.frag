#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float itemW;
    float itemH;
    float winW;
    float winH;
    float originX;
    float originY;
    float radius;
    float edgeWidth;
    float refraction;
    float dispersion;
    float ambientDim;
    float blurRadius;
    float pointerX;
    float pointerY;
    float hover;
    float clock;
    vec4 tint;
};

layout(binding = 1) uniform sampler2D source;

float sdRoundBox(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + vec2(r);
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

// Small 3x3 gaussian, sized in screen pixels. The pane stays clear; this
// only takes the digital edge off the refracted scene.
vec4 glassTap(vec2 uv) {
    vec2 px = vec2(blurRadius) / vec2(winW, winH);
    vec4 c = texture(source, clamp(uv, vec2(0.0), vec2(1.0))) * 0.25;
    c += texture(source, clamp(uv + vec2(px.x, 0.0), vec2(0.0), vec2(1.0))) * 0.125;
    c += texture(source, clamp(uv - vec2(px.x, 0.0), vec2(0.0), vec2(1.0))) * 0.125;
    c += texture(source, clamp(uv + vec2(0.0, px.y), vec2(0.0), vec2(1.0))) * 0.125;
    c += texture(source, clamp(uv - vec2(0.0, px.y), vec2(0.0), vec2(1.0))) * 0.125;
    c += texture(source, clamp(uv + px, vec2(0.0), vec2(1.0))) * 0.0625;
    c += texture(source, clamp(uv - px, vec2(0.0), vec2(1.0))) * 0.0625;
    c += texture(source, clamp(uv + vec2(px.x, -px.y), vec2(0.0), vec2(1.0))) * 0.0625;
    c += texture(source, clamp(uv + vec2(-px.x, px.y), vec2(0.0), vec2(1.0))) * 0.0625;
    return c;
}

void main() {
    vec2 size = vec2(itemW, itemH);
    vec2 p = qt_TexCoord0 * size;
    vec2 center = size * 0.5;
    vec2 halfSize = center;

    float d = sdRoundBox(p - center, halfSize, radius);
    float alpha = 1.0 - smoothstep(-0.8, 0.8, d);
    if (alpha <= 0.002) discard;

    // Outward normal of the rounded rectangle (analytic SDF gradient).
    vec2 q = p - center;
    vec2 b = halfSize - vec2(radius);
    vec2 closest = clamp(q, -b, b);
    vec2 delta = q - closest;
    vec2 nOut = length(delta) > 0.0001 ? normalize(delta) : normalize(q + vec2(0.0001));
    vec2 nIn = -nOut;

    float edgeDist = max(0.0, -d);
    float edge = 1.0 - smoothstep(0.0, edgeWidth, edgeDist);
    float bevel = pow(edge, 2.0);

    // ------------------------------------------------------------------
    // Lens math: the bevel bends the backdrop inward, with a small overall
    // magnification and a living ripple along the rim.
    // ------------------------------------------------------------------
    vec2 offset = nIn * bevel * refraction;
    offset += (center - p) * 0.009;

    vec2 pointer = vec2(pointerX, pointerY);
    vec2 dp = p - pointer;
    float pointerFalloff = exp(-dot(dp, dp) / (2.0 * 105.0 * 105.0)) * hover;
    offset += (pointer - p) * pointerFalloff * 0.06;

    offset += vec2(
        sin(p.y * 0.045 + clock * 1.05),
        cos(p.x * 0.038 - clock * 0.85)
    ) * bevel * 1.15;

    // Sample the full-window backdrop, but only the region under this panel.
    vec2 samplePx = vec2(originX, originY) + p + offset;
    vec2 uv = samplePx / vec2(winW, winH);
    vec2 dir = normalize(offset + vec2(0.00001));
    vec2 dispUV = dir * (dispersion * (0.12 + bevel * 1.3) / vec2(winW, winH));

    vec4 sampled = glassTap(uv);
    float red = glassTap(uv + dispUV).r;
    float blue = glassTap(uv - dispUV).b;
    vec3 col = vec3(red, sampled.g, blue);

    // Transparent source (still loading) falls back to a dim glass body.
    vec3 fallback = vec3(0.075, 0.115, 0.17);
    col = mix(fallback, col, smoothstep(0.0, 0.55, sampled.a));

    // The source already carries the backdrop grade; add only the glass's
    // own absorption, plus the scrim of any overlay it lives in.
    col = mix(col, vec3(0.03, 0.045, 0.07), 0.07);
    col = mix(col, tint.rgb, clamp(tint.a, 0.0, 0.4) * 0.55);
    col *= 0.97 * (1.0 - clamp(ambientDim, 0.0, 0.8));

    // ------------------------------------------------------------------
    // Specular rim: a bright, directional bevel line plus fresnel sheen.
    // ------------------------------------------------------------------
    float fresnel = pow(1.0 - smoothstep(0.0, edgeWidth * 1.35, edgeDist), 2.3);
    vec3 N = normalize(vec3(nIn * 0.9, 0.55));
    vec3 L = normalize(vec3(-0.45, -0.62, 0.65));
    float spec = pow(max(dot(N, L), 0.0), 2.4);
    float rimLine = smoothstep(2.4, 0.0, edgeDist);
    float topLeft = clamp((nIn.y * -0.55 + nIn.x * -0.45) * 0.5 + 0.5, 0.0, 1.0);

    col += vec3(1.0, 0.985, 0.95) * (
        spec * fresnel * 0.28
        + rimLine * (0.10 + 0.13 * topLeft) * (0.8 + 0.4 * hover)
    );

    // Inner shadow on the lower-right bevel.
    float shade = smoothstep(0.0, edgeWidth * 1.1, edgeDist)
        * clamp(nOut.x * 0.5 + nOut.y * 0.5, 0.0, 1.0);
    col *= 1.0 - shade * 0.2;

    // Pointer highlight.
    col += vec3(1.0) * pointerFalloff * 0.11;

    // Slow liquid highlight traveling across the pane.
    float diag = fract((p.x / max(itemW, 1.0)) * 0.68 + (p.y / max(itemH, 1.0)) * 0.32);
    float bandPos = mod(clock * 0.055, 1.5) - 0.25;
    float band = exp(-pow((diag - bandPos) * 4.8, 2.0));
    col += vec3(1.0) * band * (0.03 + 0.03 * hover);

    fragColor = vec4(col, 1.0) * qt_Opacity * alpha;
}
