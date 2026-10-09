// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Barrulus
// Workspace reveal: shared output coordinates keep both root masks aligned.
uniform vec4 umbriel_workspace_rect;
uniform vec2 umbriel_workspace_axis;

const float FIRE_WIDTH = 0.035; // Fraction of the output's shorter dimension.
const float RAGGEDNESS = 0.045;
const float INTENSITY = 1.0; // 0..1; affects artwork, not workspace coverage.

float wh_hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float wh_noise(vec2 p) {
    vec2 cell = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(wh_hash(cell), wh_hash(cell + vec2(1.0, 0.0)), f.x),
               mix(wh_hash(cell + vec2(0.0, 1.0)), wh_hash(cell + vec2(1.0)), f.x), f.y);
}

vec4 animation(vec2 uv) {
    vec4 source = umbriel_sample(uv);
    float p = umbriel_clamped_progress;
    bool incoming = umbriel_direction > 0.0;
    if (p <= 0.0) return incoming ? vec4(0.0) : source;
    if (p >= 1.0) return incoming ? source : vec4(0.0);

    // These optional uniforms are only populated for workspace reveal.
    if (min(umbriel_workspace_rect.z, umbriel_workspace_rect.w) <= 0.0)
        return source;
    vec2 outputSize = umbriel_size / umbriel_workspace_rect.zw;
    float unit = max(min(outputSize.x, outputSize.y), 1.0);
    vec2 outputUV = umbriel_workspace_rect.xy + uv * umbriel_workspace_rect.zw;
    vec2 center = vec2(0.5) - 0.16 * umbriel_workspace_axis;
    vec2 point = (outputUV - center) * outputSize / unit;
    float farCorner = length(max(center, vec2(1.0) - center) * outputSize / unit);

    // Use the shared seed and progress, never per-root clocks or local UV noise.
    // Reversing a swipe therefore retraces exactly the same flame front.
    vec2 drift = point * 8.0 + umbriel_random_seed.xy * 19.0 - vec2(0.0, p * 3.5);
    float smoke = 0.60 * wh_noise(drift)
                + 0.28 * wh_noise(drift * 2.03 + vec2(4.7))
                + 0.12 * wh_noise(drift * 4.11);
    float width = max(FIRE_WIDTH, 0.001);
    float ragged = max(RAGGEDNESS, 0.0);
    float margin = 3.0 * width + ragged;
    float radius = mix(-margin, farCorner + margin, p * p * (3.0 - 2.0 * p));
    float distanceToFire = length(point) - radius + (smoke - 0.5) * 2.0 * ragged;
    float pixel = 1.0 / (unit * max(umbriel_scale, 0.001));
    float revealed = 1.0 - smoothstep(-pixel, pixel, distanceToFire);
    float coverage = incoming ? revealed : 1.0 - revealed;

    float envelope = smoothstep(0.025, 0.16, p) * (1.0 - smoothstep(0.80, 0.98, p));
    float edge = abs(distanceToFire);
    float halo = 1.0 - smoothstep(0.0, width * 2.8, edge);
    float flame = 1.0 - smoothstep(width * 0.12, width * (0.55 + smoke), edge);
    float core = 1.0 - smoothstep(0.0, width * 0.18 + pixel, edge);
    float witch = smoothstep(0.52, 0.78, wh_noise(drift * 0.65 + vec2(13.0, 7.0)));
    vec3 fire = mix(vec3(1.0, 0.22, 0.018), vec3(0.30, 0.90, 0.055), witch);
    fire = mix(fire, vec3(1.0, 0.87, 0.36), core * 0.88);

    float strength = clamp(INTENSITY, 0.0, 1.0) * envelope;
    // Tint within existing coverage: transparent margins stay transparent,
    // and complementary incoming/outgoing masks cannot paint duplicate fire.
    vec3 color = source.rgb * (1.0 - strength * halo * 0.58);
    color = mix(color, vec3(0.12, 0.025, 0.17) * source.a, strength * halo * 0.22);
    color = mix(color, fire * source.a, strength * flame);
    return vec4(color, source.a) * coverage;
}
