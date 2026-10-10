// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Barrulus
// Adapted from the session workspace-pair shader to the full-scene reveal API.
uniform vec2 umbriel_workspace_axis;

float workspace_sign() {
    return umbriel_workspace_axis.x + umbriel_workspace_axis.y < 0.0 ? -1.0 : 1.0;
}

// A dark, irregular wave turns the outgoing image into coloured mosaic tiles,
// then flips the tiles into the destination. Both images stay undistorted.
// Forward: top-left to bottom-right. Backward: bottom-left to top-right.
const float band_width = 0.42;
const float tile_size = 22.0;
const vec3 dark_purple = vec3(0.055, 0.045, 0.12);
const vec3 purple = vec3(0.22, 0.16, 0.38);
const vec3 lavender = vec3(0.65, 0.61, 0.91);
const vec3 moon_yellow = vec3(0.98, 0.93, 0.61);

float wave_hash(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * 0.1031);
    q += dot(q, q.yzx + 33.33 + umbriel_random_seed.x);
    return fract((q.x + q.y) * q.z);
}

float wave_noise(vec2 point) {
    vec2 cell = floor(point);
    vec2 f = fract(point);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(wave_hash(cell), wave_hash(cell + vec2(1.0, 0.0)), f.x),
               mix(wave_hash(cell + vec2(0.0, 1.0)), wave_hash(cell + 1.0), f.x), f.y);
}

vec4 animation(vec2 uv) {
    float p = umbriel_clamped_progress;
    if (p <= 0.0) return umbriel_sample(uv);
    if (p >= 1.0) return umbriel_sample_incoming(uv);

    vec4 from = umbriel_sample(uv);
    vec4 to = umbriel_sample_incoming(uv);
    vec2 output_size = max(umbriel_size, vec2(1.0));
    vec2 grid = max(output_size / max(tile_size, 4.0), vec2(1.0));
    // Stagger rows to break up long straight seams.
    vec2 tiled = uv * grid;
    float row = floor(tiled.y);
    tiled.x += mod(row, 2.0) * 0.5;
    vec2 cell = floor(tiled);
    vec2 local = fract(tiled);
    vec2 center = (cell + 0.5 - vec2(mod(row, 2.0) * 0.5, 0.0)) / grid;
    float random = wave_hash(cell);

    // Reflect Y for reverse navigation: X still travels from left to right.
    vec2 sweep_uv = center;
    if (workspace_sign() < 0.0) sweep_uv.y = 1.0 - sweep_uv.y;
    float along = dot(sweep_uv, output_size) / (output_size.x + output_size.y);
    float width = clamp(band_width, 0.12, 0.70);
    // Coherent patches make an uneven front and vary its thickness. These
    // offsets stay fixed for the transaction, so the wave does not shimmer.
    float patch = wave_noise(sweep_uv * vec2(5.0, 7.0) + 13.1);
    float detail = wave_noise(sweep_uv * vec2(13.0, 11.0) + 31.7);
    along += (patch - 0.5) * 0.14 + (detail - 0.5) * 0.045;
    float local_width = width * mix(0.72, 1.18, patch);
    // Padding lets the entire coloured band enter and leave beyond the corners.
    float front = mix(-width * 1.15, 1.0 + width * 1.15, p);
    float phase = (front - along) / local_width + 0.5 + (random - 0.5) * 0.24;

    // A broad opaque colour interval gives the palette time to read clearly.
    float tint = smoothstep(0.02, 0.26, phase);
    float reveal = smoothstep(0.62, 0.94, phase);
    // Most tiles remain dark. Sparse lavender and yellow tiles supply the
    // website's contrast without turning the whole band into a bright flash.
    vec3 color = mix(dark_purple, purple, 0.18 + 0.65 * patch);
    color *= 0.82 + 0.18 * random;
    float accent = wave_hash(cell + 93.7);
    float lavender_weight = smoothstep(0.84, 0.97, accent);
    color = mix(color, lavender, lavender_weight * (0.65 + 0.25 * detail));
    float yellow_weight = smoothstep(0.975, 0.995, accent);
    color = mix(color, moon_yellow, yellow_weight * 0.9);

    float alpha = mix(from.a, to.a, reveal);
    vec4 colored = vec4(color * alpha, alpha);
    // A fine shaded seam distinguishes the little tiles within the colour band.
    float edge = min(min(local.x, 1.0-local.x), min(local.y, 1.0-local.y));
    float seam = smoothstep(0.0, 0.035, edge);
    colored.rgb *= mix(0.84, 1.0, seam);

    // Rotate the coloured face away, then show the destination on its back.
    float flip = smoothstep(0.57, 0.98, phase);
    float face_width = abs(cos(3.14159265 * flip));
    float aa = min(0.20, 1.0 / max(tile_size * umbriel_scale, 1.0));
    float face = 1.0 - smoothstep(max(0.0, face_width - aa), face_width + aa,
                                 abs(local.x - 0.5) * 2.0);
    face *= smoothstep(0.0, 0.05, face_width);
    vec4 base = mix(from, to, smoothstep(0.53, 0.72, phase));
    vec4 tile = flip < 0.5 ? colored : to;
    // Shading vanishes as each tile completes its turn.
    tile.rgb *= 0.75 + 0.25 * face_width;
    vec4 result = mix(base, tile, tint * face);
    return mix(result, to, smoothstep(0.94, 1.0, phase));
}
