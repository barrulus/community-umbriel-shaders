// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Barrulus
// Adapted from the session workspace-pair shader to the full-scene reveal API.
uniform vec2 umbriel_workspace_axis;

float workspace_sign() {
    return umbriel_workspace_axis.x + umbriel_workspace_axis.y < 0.0 ? -1.0 : 1.0;
}

// Continuous white-blue light shafts replace the image, carry its vertical
// streaks, then clear to reveal the destination. No pixel-noise dissolve.
const float energy_strength = 1.0;
const float beam_spacing = 30.0;
const float beam_width = 1.8;
const vec3 beam_color = vec3(0.53, 0.58, 0.94);
const vec3 core_color = vec3(0.94, 0.97, 1.0);

float beam_hash(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * 0.1031);
    q += dot(q, q.yzx + 33.33 + umbriel_random_seed.x);
    return fract((q.x + q.y) * q.z);
}

// Core, halo and flare for full-height shafts, with light travelling vertically.
vec3 transporter_lines(vec2 pixel, float p, float direction, float layer) {
    float spacing = max(beam_spacing, 12.0) * (1.0 + layer * 0.63);
    float column = floor(pixel.x / spacing);
    float random = beam_hash(vec2(column, 21.0 + layer * 71.0));
    float center = (column + 0.22 + 0.56 * random) * spacing;
    // Less than one pixel of wavering keeps the light unmistakably vertical.
    float shimmer = sin(pixel.y * 0.017 + p * 18.0 + random * 30.0) * 0.55;
    float dx = abs(pixel.x - center - shimmer);
    float width = max(beam_width, 0.5) * (0.60 + random * 0.80);
    float core = exp(-pow(dx / width, 2.0));
    float halo = exp(-pow(dx / (width * 4.5), 2.0));
    float veil = exp(-pow(dx / (width * 8.0), 2.0));
    float travel = fract(pixel.y / (210.0 + random * 190.0)
        + direction * p * (2.4 + random) + random);
    float knot = exp(-pow((travel - 0.5) * 25.0, 2.0));
    float ribbon = 0.68 + 0.32 * sin(pixel.y * 0.008 + direction * p * 17.0 + random * 12.0);
    // Keep a steady connected core; moving knots modulate it without chopping it.
    float pulse = 0.78 + 0.22 * sin(p * 15.0 + random * 19.0);
    float flare = exp(-pow(dx / (width * 3.0), 2.0)) * knot;
    return vec3(core * (0.72 + 0.28 * ribbon),
                (halo * 0.58 + veil * 0.15) * pulse,
                flare * 0.85) * mix(0.65, 1.0, random);
}

// Sparse four-point glints drifting through the spaces between the shafts.
float transporter_sparkles(vec2 pixel, float p, float direction) {
    vec2 moving = pixel + vec2(0.0, direction * p * 105.0);
    vec2 spacing = vec2(19.0, 29.0);
    vec2 cell = floor(moving / spacing);
    vec2 local = fract(moving / spacing);
    float random = beam_hash(cell + 127.0);
    vec2 center = vec2(0.30 + 0.40 * random,
        0.30 + 0.40 * beam_hash(cell + 59.0));
    vec2 delta = (local - center) * spacing;
    float radius = 0.9 + 1.3 * random;
    float dot_light = exp(-dot(delta, delta) / (radius * radius));
    float cross_light = exp(-abs(delta.x) * 1.9 - abs(delta.y) * 0.28)
        + exp(-abs(delta.y) * 1.9 - abs(delta.x) * 0.34);
    float glow = exp(-dot(delta, delta) / 18.0) * 0.14;
    float twinkle = pow(0.5 + 0.5 * sin(p * 39.0 + random * 31.0), 3.0);
    return (dot_light + cross_light * 0.45 + glow)
        * (0.12 + 0.88 * twinkle) * smoothstep(0.20, 0.55, random);
}

float transporter_handoff(vec2 pixel, float p, float height) {
    // Small staggered pieces have widely separated start times, so intact
    // portions of both workspaces coexist throughout the middle of the effect.
    vec2 tiled = pixel / vec2(68.0, 46.0);
    tiled.x += mod(floor(tiled.y), 2.0) * 0.5;
    vec2 cell = floor(tiled);
    float random = beam_hash(cell + 213.7);
    float start = 0.06 + random * 0.58 + height * 0.02;
    return smoothstep(start, start + 0.28, p);
}

vec4 animation(vec2 uv) {
    float p = umbriel_clamped_progress;
    if (p <= 0.0) return umbriel_sample(uv);
    if (p >= 1.0) return umbriel_sample_incoming(uv);
    vec2 size = max(umbriel_size, vec2(1.0));
    vec2 pixel = uv * size;
    float direction = workspace_sign() < 0.0 ? -1.0 : 1.0;
    float height = direction > 0.0 ? 1.0 - uv.y : uv.y;
    float column = floor(pixel.x / max(beam_spacing, 12.0));
    float random = beam_hash(vec2(column, 81.0));

    // Light grows from the beaming edge, fills the image, and drains away.
    // Long overlapping envelopes conceal the source change behind each shaft.
    float start = height * 0.16 + random * 0.045;
    float light_on = smoothstep(start, start + 0.17, p);
    float light_off = 1.0 - smoothstep(0.68 + height * 0.12, 0.86 + height * 0.12, p);
    float field = light_on * light_off;
    float handoff = transporter_handoff(pixel, p, height);
    vec4 from = umbriel_sample(uv);
    vec4 to = umbriel_sample_incoming(uv);
    vec4 native = mix(from, to, handoff);

    vec3 lines = transporter_lines(pixel, p, direction, 0.0);
    lines += transporter_lines(pixel + vec2(11.0, 0.0), p, direction, 1.0) * 0.65;
    float strength = clamp(energy_strength, 0.0, 2.0);
    float core = min(lines.x + lines.z, 1.0);
    float halo = min(lines.y, 1.0);

    // Vertical sampling stretches the source content only inside narrow light
    // columns, so data itself turns into beams rather than just gaining noise.
    float anchor = direction > 0.0 ? 1.0 : 0.0;
    vec2 streak_uv = vec2(uv.x, mix(uv.y, anchor, field * 0.80));
    vec4 streak = mix(umbriel_sample(streak_uv), umbriel_sample_incoming(streak_uv), handoff);
    vec4 result = mix(native, streak, min(field * core * 0.70, 1.0));
    result.rgb *= 1.0 - field * 0.42;

    // Broad lavender-blue halos and bright white-blue cores; no random colours.
    float halo_mix = min(field * strength * halo * 0.62, 0.80);
    float core_mix = min(field * strength * core, 0.97);
    result.rgb = mix(result.rgb, beam_color * result.a, halo_mix);
    result.rgb = mix(result.rgb, core_color * result.a, core_mix);
    float sparkles = transporter_sparkles(pixel, p, direction);
    float sparkle_mix = min(field * strength * sparkles * (1.0 - core * 0.75), 0.92);
    result.rgb = mix(result.rgb, core_color * result.a, sparkle_mix);
    return result;
}
