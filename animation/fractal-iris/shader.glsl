// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Barrulus. Original procedural artwork.

const float INTENSITY = 0.94; // 0..1; opacity of the rolling fractal lip.
const float BAND_WIDTH = 0.14; // Arrival-time width of the coloured rolling edge.
const float DETAIL_SCALE = 0.24; // Fractal feature scale, fraction of the shorter dimension.
const float ADVANCE_TEARS = 0.12; // 0..0.2; how far small tears lead the main front.

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

// The front traverses a fixed, folded fractal landscape. Each pixel has an
// arrival time: changing the level splits contours, opens tears and merges
// them into the main opening. Neither geometry nor texture is zoomed.
vec3 psyche_growth(vec2 point, vec2 size, float pixel) {
    float unit = min(size.x, size.y);
    float radial = length(point) / max(length(size * 0.5), 1.0);
    float feature = max(unit * clamp(DETAIL_SCALE, 0.10, 0.5), 8.0);
    vec2 q = psyche_fold(point / feature, 0.0);
    // Bounded domain warping keeps new folds appearing toward the corners.
    q = 1.4 * vec2(sin(q.x + 0.7 * sin(q.y * 1.7)),
                   sin(q.y - 0.7 * sin(q.x * 1.3)));
    vec2 mainField = psyche_fractal(q, 0.52, pixel / feature);
    vec2 fineField = psyche_fractal(q * 1.7 + vec2(0.31, 0.57), 0.71, pixel / feature * 1.7);
    float terrain = smoothstep(0.22, 0.72, mainField.y);
    float tears = smoothstep(0.58, 0.80, fineField.y);
    float spread = smoothstep(0.0, 0.16, radial);
    float arrival = 0.58 * radial + 0.42 * terrain * spread;
    arrival -= clamp(ADVANCE_TEARS, 0.0, 0.2) * tears * spread;
    arrival = clamp(0.025 + 0.95 * arrival, 0.015, 0.985);
    return vec3(arrival, mainField.y, fineField.y);
}

vec4 animation(vec2 uv) {
    float p = umbriel_clamped_progress;
    if (p <= 0.0) return umbriel_sample(uv);
    if (p >= 1.0) return umbriel_sample_incoming(uv);
    vec2 size = max(umbriel_size, vec2(1.0));
    vec2 point = (uv - 0.5) * size;
    float pixel = 0.75 / max(umbriel_scale, 0.01);
    vec3 growth = psyche_growth(point, size, pixel);
    float distance = growth.x - p;
    float band = clamp(BAND_WIDTH, 0.03, 0.24);
    // Outside the entire lip, skip the slope estimates and second scene sample.
    if (distance > band) return umbriel_sample(uv);
    if (distance < -band) return umbriel_sample_incoming(uv);
    // Estimate the spatial slope for antialiasing steep recursive contours.
    // This stays independent of progress, retaining monotonic visibility.
    vec2 stepDir = vec2(point.x < 0.0 ? -pixel : pixel, point.y < 0.0 ? -pixel : pixel);
    float dx = psyche_growth(point + vec2(stepDir.x, 0.0), size, pixel).x - growth.x;
    float dy = psyche_growth(point + vec2(0.0, stepDir.y), size, pixel).x - growth.x;
    float aa = clamp(length(vec2(dx, dy)), 0.001, 0.022);
    float reveal = 1.0 - smoothstep(-aa, aa, distance);
    vec4 source = mix(umbriel_sample(uv), umbriel_sample_incoming(uv), reveal);
    float envelope = smoothstep(0.0, 0.06, p) * (1.0 - smoothstep(0.88, 1.0, p));
    float lip = 1.0 - smoothstep(band * 0.18, band, abs(distance));
    // Several nested contours roll through the lip as it crosses new folds.
    float curl = distance / band;
    float ridges = 0.5 + 0.5 * cos(curl * 19.0 + growth.z * 12.0);
    vec3 colour = psyche_colour(growth.y * 1.7 + curl * 0.65 + p * 0.25);
    colour *= 0.36 + 0.64 * ridges;
    float tip = 1.0 - smoothstep(aa, aa * 3.0 + 0.002, abs(distance));
    colour = mix(colour, vec3(0.88, 1.0, 0.97), tip * 0.70);
    float opacity = lip * envelope * clamp(INTENSITY, 0.0, 1.0);
    return vec4(mix(source.rgb, colour * source.a, opacity), source.a);
}
