// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Barrulus. Original procedural artwork.

const float INTENSITY = 0.055; // 0..0.15 recommended; maximum tint opacity.
const float PATTERN_SCALE = 56.0; // Logical pixels per small kaleidoscope tile.
const float SPEED = 0.18; // Motion phase per second; zero freezes the pattern.

// Twelve mirrored wedges give the fractal a true kaleidoscope symmetry.
vec2 psyche_fold(vec2 p, float rotation) {
    float radius = length(p);
    float angle = radius > 0.00001 ? atan(p.y, p.x) : 0.0;
    float wedge = 1.0471975512;
    angle = abs(mod(angle + rotation + wedge * 0.5, wedge) - wedge * 0.5);
    return radius * vec2(cos(angle), sin(angle));
}

// Six bounded inversion/fold iterations form nested branching orbit traps.
// Keep this helper identical across the Psychedelic pack; no texture or history.
vec2 psyche_fractal(vec2 p, float phase, float pixel) {
    float c = cos(phase), s = sin(phase);
    mat2 turn = mat2(c, -s, s, c);
    vec2 z = p;
    float trap = 1.0;
    float field = 0.0;
    float weight = 0.5;
    for (int i = 0; i < 6; ++i) {
        z = turn * abs(z);
        z = z / clamp(dot(z, z), 0.24, 2.4) - vec2(0.92, 0.64);
        float orbit = abs(length(z) - 0.72);
        trap = min(trap, orbit);
        field += weight * exp(-3.0 * orbit);
        weight *= 0.5;
    }
    float line = 1.0 - smoothstep(0.012, 0.038 + min(pixel, 0.035), trap);
    return vec2(line, clamp(field, 0.0, 1.0));
}
vec3 psyche_colour(float t) {
    return 0.52 + 0.48 * cos(6.28318530718 * (t + vec3(0.0, 0.33, 0.67)));
}


vec4 window(vec2 uv) {
    vec4 source = umbriel_sample(uv);
    float time = umbriel_time * SPEED;
    float scale = max(PATTERN_SCALE, 24.0);
    vec2 point = (uv - 0.5) * umbriel_size / scale;
    vec2 cell = floor(point + 0.5);
    vec2 local = fract(point + 0.5) - 0.5;
    float phase = 0.45 * sin(cell.x * 1.7 + cell.y * 2.3);
    // Motion stays inside each small rosette; content is never displaced.
    vec2 q = psyche_fold(local * (3.0 + 0.08 * sin(time + phase)), time * 0.55 + phase);
    vec2 f = psyche_fractal(q, 0.52 + 0.08 * sin(time * 0.8 + phase),
        3.0 / (scale * max(umbriel_scale, 0.01)));
    float envelope = 1.0 - smoothstep(0.40, 0.50, length(local));
    vec3 colour = psyche_colour(f.y * 1.25 + time * 0.10 + phase * 0.15);
    float radius = length(q);
    float angle = radius > 0.00001 ? atan(q.y, q.x) : 0.0;
    float petal = abs(radius - (0.82 + 0.23 * cos(angle * 6.0)));
    float aa = 2.0 / (scale * max(umbriel_scale, 0.01));
    float outline = 1.0 - smoothstep(0.018, 0.035 + aa, petal);
    float inner = abs(radius - (0.44 - 0.12 * cos(angle * 6.0)));
    outline = max(outline, 1.0 - smoothstep(0.012, 0.025 + aa, inner));
    float lace = 1.0 - smoothstep(0.12, 0.38, abs(sin(f.y * 25.0)));
    float ink = max(outline, lace * 0.55);
    float amount = clamp(INTENSITY, 0.0, 1.0) * envelope * ink;
    return vec4(mix(source.rgb, colour * source.a, amount), source.a);
}
