// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Barrulus
// Adapted from the session workspace-pair shader to the full-scene reveal API.
uniform vec2 umbriel_workspace_axis;

float workspace_sign() {
    return umbriel_workspace_axis.x + umbriel_workspace_axis.y < 0.0 ? -1.0 : 1.0;
}

// Full-screen video breakup and phased block replacement, without a travelling
// wave. Only progress and the held seed drive the glitch sequence.
const float glitch_strength = 1.0;
const vec2 block_size = vec2(96.0, 32.0);
const vec3 dark_purple = vec3(0.055, 0.045, 0.12);
const vec3 lavender = vec3(0.65, 0.61, 0.91);
const vec3 moon_yellow = vec3(0.98, 0.93, 0.61);

float phase_hash(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * 0.1031);
    q += dot(q, q.yzx + 33.33 + umbriel_random_seed.x);
    return fract((q.x + q.y) * q.z);
}

vec4 phase_sample(vec2 uv, float handoff) {
    // Keep torn edge strips covered instead of exposing the live scene below.
    uv = clamp(uv, vec2(0.0), vec2(1.0));
    return mix(umbriel_sample(uv), umbriel_sample_incoming(uv), handoff);
}

vec4 animation(vec2 uv) {
    float p = umbriel_clamped_progress;
    if (p <= 0.0) return umbriel_sample(uv);
    if (p >= 1.0) return umbriel_sample_incoming(uv);

    float envelope = 16.0 * p * p * (1.0-p) * (1.0-p);
    float strength = clamp(glitch_strength, 0.0, 2.0);
    float amount = envelope * strength;
    vec2 size = max(umbriel_size, vec2(1.0));
    vec2 pixel = uv * size;
    vec2 cell = floor(pixel / max(block_size, vec2(8.0)));
    float cell_seed = phase_hash(cell + 91.2);
    // Broad overlapping dissolves happen at different times across the whole
    // image. Their placement is independent of either navigation direction.
    float start = 0.08 + 0.44 * cell_seed;
    float local_handoff = smoothstep(start, start + 0.40, p);
    float global_handoff = smoothstep(0.04, 0.96, p);
    float handoff = mix(global_handoff, local_handoff, min(strength * 0.75, 1.0));

    float tick = floor(p * 28.0);
    float strip = floor(pixel.y / 7.0);
    float band = floor(pixel.y / 43.0);
    float band_random = phase_hash(vec2(band, tick) + 17.0);
    float tear = smoothstep(0.72, 0.92, band_random);
    float jitter = phase_hash(vec2(strip, tick) + 53.0) - 0.5;
    float block_random = phase_hash(cell + vec2(tick * 3.7, tick * 1.3));
    float block_glitch = smoothstep(0.87, 0.98, block_random);
    float sign = workspace_sign() < 0.0 ? -1.0 : 1.0;
    vec2 displaced = uv;
    displaced.x += sign * amount * (0.055 * tear * (band_random - 0.5)
        + 0.006 * jitter + 0.018 * block_glitch * (cell_seed - 0.5));
    displaced.y += amount * block_glitch * (cell_seed - 0.5) * 0.008;

    // Misregistered video channels remain premultiplied by central coverage.
    float split = amount * (0.0015 + 0.005 * tear + 0.002 * block_glitch);
    vec4 center = phase_sample(displaced, handoff);
    vec4 red = phase_sample(displaced + vec2(split, 0.0), handoff);
    vec4 blue = phase_sample(displaced - vec2(split, 0.0), handoff);
    vec3 rgb = center.rgb / max(center.a, 0.0001);
    float chroma = min(amount * 0.85, 1.0);
    rgb.r = mix(rgb.r, red.r / max(red.a, 0.0001), chroma);
    rgb.b = mix(rgb.b, blue.b / max(blue.a, 0.0001), chroma);

    float scanline = 0.5 + 0.5 * sin(pixel.y * 3.14159265);
    rgb *= 1.0 - min(amount * (0.075 * scanline + 0.16 * tear), 0.7);
    // Most interference is dark purple. Sparse coloured specks supply accents,
    // without a bright full-screen flash or a blanket of pastel blocks.
    rgb = mix(rgb, dark_purple, min(amount * block_glitch * 0.48, 0.8));
    float grain = phase_hash(floor(pixel / vec2(2.0, 1.0)) + tick * 19.7);
    float speck = smoothstep(0.984, 0.998, grain) * (0.25 + 0.75 * tear);
    vec3 accent = mix(lavender, moon_yellow, step(0.997, grain));
    rgb = mix(rgb, accent, min(amount * speck * 0.42, 0.7));
    return vec4(rgb * center.a, center.a);
}
