// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Barrulus
// A centre-out reveal through perforated, ghost-lit fabric.

const float RAGGEDNESS = 1.0; // 0..2; size of tears and satellite holes.
const float GLOW_WIDTH = 0.026; // Fraction of the shorter output dimension.
const float INTENSITY = 0.85; // 0..1; artwork strength, independent of coverage.
const vec3 PEARL = vec3(0.95, 0.98, 1.0);
const vec3 MINT = vec3(0.65, 0.89, 0.83);
const vec3 LAVENDER = vec3(0.80, 0.74, 0.94);

float gt_hash(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973)
        + umbriel_random_seed.xyz);
    q += dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z);
}

float gt_noise(vec2 p) {
    vec2 cell = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(gt_hash(cell), gt_hash(cell + vec2(1.0, 0.0)), f.x),
               mix(gt_hash(cell + vec2(0.0, 1.0)), gt_hash(cell + vec2(1.0)), f.x), f.y);
}

vec4 animation(vec2 uv) {
    float p = umbriel_clamped_progress;
    if (p <= 0.0) return umbriel_sample(uv);
    if (p >= 1.0) return umbriel_sample_incoming(uv);

    float unit = max(min(umbriel_size.x, umbriel_size.y), 1.0);
    vec2 point = (uv - vec2(0.5)) * umbriel_size / unit;
    float radial = length(point);
    float corner = length(0.5 * umbriel_size / unit);
    float pixel = 1.0 / (unit * max(umbriel_scale, 0.001));
    float roughness = clamp(RAGGEDNESS, 0.0, 2.0);
    float width = max(GLOW_WIDTH, 0.002);

    // A stationary arrival field makes forward motion strictly erosive:
    // revealed fabric cannot grow back, and reversed swipes retrace it exactly.
    vec2 warp = vec2(gt_noise(point * 3.1 + 7.0),
                     gt_noise(point * 3.1 + 39.0)) - 0.5;
    vec2 fabric = point + 0.16 * warp;
    float folds = gt_noise(fabric * 5.0);
    float tears = gt_noise(fabric * 13.0 + 17.0);
    float pores = gt_noise(fabric * 31.0 + 51.0);
    float fibres = gt_noise(fabric * 67.0 + 83.0);
    // High-frequency terms are deliberately strong enough to create local
    // minima: detached holes and thin islands, rather than a noisy circle.
    float erosion = 0.25 * (folds - 0.5) + 0.20 * (tears - 0.5)
                  + 0.16 * (pores - 0.5) + 0.035 * (fibres - 0.5);
    float arrival = max(radial * 0.25, radial + roughness * erosion
                        * smoothstep(0.015, 0.22, radial));
    float margin = 0.323 * roughness + 3.0 * width + 2.0 * pixel;
    float travel = p * p * (3.0 - 2.0 * p);
    float radius = mix(-2.0 * pixel, corner + margin, travel);
    float edge = arrival - radius;
    float revealed = 1.0 - smoothstep(-pixel, pixel, edge);
    vec4 source = mix(umbriel_sample(uv), umbriel_sample_incoming(uv), revealed);

    float envelope = smoothstep(0.0, 0.09, p)
                   * (1.0 - smoothstep(0.83, 1.0, p));
    float distanceToEdge = abs(edge);
    float mist = 1.0 - smoothstep(0.0, width * 3.0, distanceToEdge);
    float veil = 1.0 - smoothstep(width * 0.12, width, distanceToEdge);
    float thread = 1.0 - smoothstep(pixel, width * 0.16 + pixel, distanceToEdge);
    vec3 tint = mix(MINT, LAVENDER, smoothstep(0.20, 0.80, folds));
    vec3 spectral = mix(tint, PEARL, 0.40 + 0.60 * thread);
    float strength = clamp(INTENSITY, 0.0, 1.0) * envelope;

    // Soft smoke and pale, luminous fibres; no orange flame or black char.
    vec3 color = mix(source.rgb, tint * source.a,
                     strength * mist * (0.13 + 0.12 * tears));
    color = mix(color, spectral * source.a,
                strength * max(veil * (0.40 + 0.25 * fibres), thread * 0.96));
    return vec4(color, source.a);
}
