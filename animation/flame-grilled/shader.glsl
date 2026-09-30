// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Barrulus
// Self-contained GLSL ES 1.00; shared by windows_in and windows_out.
float hash21(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * 0.1031);
    q += dot(q, q.yzx + 33.33 + umbriel_random_seed.x);
    return fract((q.x + q.y) * q.z);
}
float noise21(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
               mix(hash21(i + vec2(0.0, 1.0)), hash21(i + 1.0), f.x), f.y);
}
vec4 overGlow(vec4 base, vec3 tint, float alpha) {
    alpha = clamp(alpha, 0.0, 1.0);
    return vec4(tint * alpha, alpha) + base * (1.0 - alpha);
}

// Number of broad flame tongues across the window; try 9–22.
const float FLAME_COLUMNS = 15.0;
// Tallest flame as a fraction of window height; try 0.30–0.65.
const float FLAME_HEIGHT = 0.48;

vec4 animation(vec2 uv) {
    float t = clamp(umbriel_linear_progress, 0.0, 1.0);
    bool opening = umbriel_direction > 0.0;
    if (t <= 0.0) return opening ? vec4(0.0) : umbriel_sample(uv);
    if (t >= 1.0) return opening ? umbriel_sample(uv) : vec4(0.0);

    float front = opening ? mix(-0.28, 1.5, t) : mix(1.5, -0.28, t);
    // Noise travels upward along the flame body, rather than just along its edge.
    float flicker = noise21(vec2(uv.x * FLAME_COLUMNS, t * 8.0));
    float detail = noise21(vec2(uv.x * 34.0 + sin(uv.y * 12.0 - t * 10.0), uv.y * 7.0 + t * 17.0));
    float ragged = (flicker - 0.5) * 0.075 + (detail - 0.5) * 0.035;
    float d = uv.y - front + ragged;
    float mask = 1.0 - smoothstep(-0.02, 0.02, d);
    vec4 window = umbriel_sample(uv) * mask;
    float envelope = smoothstep(0.0, 0.10, t) * (1.0 - smoothstep(0.88, 1.0, t));
    float height = FLAME_HEIGHT * (0.25 + 0.75 * flicker);
    float tongues = smoothstep(-height, -height * 0.35, d)
        * (1.0 - smoothstep(0.0, 0.06, d));
    float heat = exp(-abs(d + 0.015) * 13.0);
    float texture = 0.65 + 0.35 * detail;
    float alpha = (tongues * texture + heat * 0.65) * envelope;
    window.rgb *= 1.0 - 0.65 * exp(-abs(d) * 9.0) * envelope;
    vec3 fire = mix(vec3(0.95, 0.075, 0.008), vec3(1.0, 0.48, 0.035), tongues);
    fire = mix(fire, vec3(1.0, 0.94, 0.56), heat * heat);
    return overGlow(window, fire, alpha);
}
