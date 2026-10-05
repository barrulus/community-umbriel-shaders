// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Barrulus

// Theme colours affect artwork only; palette = false restores the original RGB.
// Keep the original shade and soften highlights without changing effect opacity.
vec3 theme_color(vec3 original, float position) {
    if (umbriel_palette_count <= 0) return original;
    float value = max(original.r, max(original.g, original.b));
    float white = min(original.r, min(original.g, original.b)) / max(value, 0.0001);
    return value * mix(umbriel_palette_at(position).rgb, vec3(1.0), white * 0.75);
}

vec4 overGlow(vec4 base, vec3 tint, float alpha) {
    alpha = clamp(alpha, 0.0, 1.0);
    return vec4(tint * alpha, alpha) + base * (1.0 - alpha);
}

const float PHOSPHOR_WIDTH = 2.0;
const float BLINK_RADIUS = 10.0;

vec4 animation(vec2 uv) {
    float t = clamp(umbriel_linear_progress, 0.0, 1.0);
    bool opening = umbriel_direction > 0.0;
    if (t <= 0.0) return opening ? vec4(0.0) : umbriel_sample(uv);
    if (t >= 1.0) return opening ? umbriel_sample(uv) : vec4(0.0);

    float visible = opening ? t : 1.0 - t;
    float height = mix(0.003, 1.0, smoothstep(0.46, 1.0, visible));
    // Reserve the final fifth of shutdown for the bright central afterimage.
    float width = mix(0.004, 1.0, smoothstep(0.20, 0.49, visible));
    vec2 source = (uv - 0.5) / vec2(width, height) + 0.5;
    vec4 window = umbriel_sample(source);
    float charge = 1.0 - smoothstep(0.49, 0.94, visible);
    window.rgb = mix(window.rgb, window.a * theme_color(vec3(0.78, 0.93, 1.0), 0.25), charge);
    window *= smoothstep(0.08, 0.22, visible);
    vec2 p = (uv - 0.5) * umbriel_size;
    float line = exp(-abs(p.y) / PHOSPHOR_WIDTH) *
        (1.0 - smoothstep(width * umbriel_size.x * 0.45, width * umbriel_size.x * 0.5 + 1.0, abs(p.x)));
    float flash = smoothstep(0.025, 0.09, visible) * (1.0 - smoothstep(0.49, 0.85, visible));
    float blink = smoothstep(0.0, 0.045, visible) * (1.0 - smoothstep(0.13, 0.29, visible));
    float dotGlow = exp(-length(p / vec2(BLINK_RADIUS, BLINK_RADIUS * 0.70)));
    float core = exp(-length(p / vec2(3.5, 2.8)));
    float star = exp(-abs(p.y) / 1.2 - abs(p.x) / (BLINK_RADIUS * 2.0));
    vec4 color = overGlow(window, theme_color(vec3(0.75, 0.91, 1.0), 0.25), line * flash * 0.8);
    return overGlow(color, theme_color(vec3(0.94, 0.985, 1.0), 0.25), (dotGlow * 0.85 + core + star * 0.4) * blink);
}
