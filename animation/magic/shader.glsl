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

const float SPARKLE_DENSITY = 14.0;

vec4 animation(vec2 uv) {
    float t = clamp(umbriel_linear_progress, 0.0, 1.0);
    bool opening = umbriel_direction > 0.0;
    if (t <= 0.0) return opening ? vec4(0.0) : umbriel_sample(uv);
    if (t >= 1.0) return opening ? umbriel_sample(uv) : vec4(0.0);

    float visible = opening ? t : 1.0 - t;
    vec2 aspect = umbriel_size / max(min(umbriel_size.x, umbriel_size.y), 1.0);
    vec2 p = (uv - 0.5) * aspect;
    float life = sin(visible * 3.14159);
    float radius = mix(0.04, length(aspect) * 0.58, visible);
    float cloud = noise21(p * 7.0 + visible * 2.0);
    float d = length(p) - radius + (cloud - 0.5) * 0.2 * life;
    float reveal = (1.0 - smoothstep(-0.10, 0.05, d)) * smoothstep(0.10, 0.38, visible);
    vec4 window = umbriel_sample(uv) * reveal;
    float smoke = exp(-abs(d) * 12.0) * cloud * life * 0.7;
    window = overGlow(window, theme_color(vec3(0.57, 0.24, 0.83), 0.0), smoke);
    // Neighbor search lets each four-point sparkle drift across cell boundaries.
    vec2 field = p * SPARKLE_DENSITY;
    vec2 cell = floor(field);
    float sparkle = 0.0;
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 id = cell + vec2(float(x), float(y));
            vec2 center = id + vec2(hash21(id), hash21(id + 31.0));
            center += vec2(0.0, -visible * 0.8);
            vec2 delta = abs(field - center);
            float star = exp(-length(delta) * 24.0);
            star += exp(-delta.x * 65.0 - delta.y * 7.0) * 0.65;
            star += exp(-delta.y * 65.0 - delta.x * 7.0) * 0.65;
            float shell = exp(-abs(length(center / SPARKLE_DENSITY) - radius) * 9.0);
            float pulse = sin(visible * 24.0 + hash21(id + 7.0) * 6.28318);
            float twinkle = 0.45 + 0.55 * pulse * pulse;
            sparkle += star * shell * twinkle * life;
        }
    }
    return overGlow(window, theme_color(vec3(1.0, 0.88, 0.57), 0.5), sparkle);
}
