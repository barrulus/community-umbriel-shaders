// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Barrulus
// Adapted from the session workspace-pair shader to the full-scene reveal API.
uniform vec2 umbriel_workspace_axis;

float workspace_sign() {
    return umbriel_workspace_axis.x + umbriel_workspace_axis.y < 0.0 ? -1.0 : 1.0;
}

// Held seed only: arbitrary progress evaluation retraces the same geometry.
float reveal_hash(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973)
        + umbriel_random_seed.xyz);
    q += dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z);
}
vec2 reveal_random(vec2 p) {
    return vec2(reveal_hash(p), reveal_hash(p + vec2(37.0, 19.0)));
}
float reveal_noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(reveal_hash(i), reveal_hash(i + vec2(1.0, 0.0)), f.x),
        mix(reveal_hash(i + vec2(0.0, 1.0)), reveal_hash(i + vec2(1.0)), f.x), f.y);
}
mat2 reveal_rotation(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, s, -s, c);
}
float reveal_sign() { return workspace_sign() < 0.0 ? -1.0 : 1.0; }
float reveal_along(vec2 uv) {
    vec2 axis = abs(umbriel_workspace_axis);
    if (dot(axis, axis) < 0.5) axis = vec2(1.0, 0.0);
    float along = dot(uv, axis);
    return workspace_sign() < 0.0 ? 1.0 - along : along;
}
vec4 reveal_over(vec4 top, vec4 bottom) { return top + bottom * (1.0 - top.a); }

// Invert the perspective projection of a plane rotated about its horizontal
// centre line. Texture coordinates stay attached to the slat's original plane.
vec4 animation(vec2 uv) {
    float p = umbriel_clamped_progress;
    if (p <= 0.0) return umbriel_sample(uv);
    if (p >= 1.0) return umbriel_sample_incoming(uv);
    float rows = 18.0;
    vec4 bottom = umbriel_sample_incoming(uv), result = bottom;
    for (int neighbour = -1; neighbour <= 1; neighbour++) {
        float row = floor(uv.y * rows) + float(neighbour);
        if (row < 0.0 || row >= rows) continue;
        float cascade = (row + 0.5) / rows;
        if (workspace_sign() < 0.0) cascade = 1.0 - cascade;
        float t = clamp((p - 0.20 * cascade) / 0.74, 0.0, 1.0);
        if (t >= 1.0) continue;
        float angle = 1.57079633 * smoothstep(0.0, 1.0, t);
        float c = cos(angle), s = sin(angle) * reveal_sign();
        float center = (row + 0.5) / rows;
        float y = uv.y - center;
        // y = source_y * cos(angle) / (1 + source_y * sin(angle)/distance).
        float denominator = c - y * s / 0.35;
        if (denominator <= 0.00001) continue;
        float source_y = y / denominator;
        if (abs(source_y) >= 0.5 / rows) continue;
        float perspective = 1.0 + source_y * s / 0.35;
        vec2 source = vec2((uv.x - 0.5) * perspective + 0.5, center + source_y);
        vec4 top = umbriel_sample(source);
        top.rgb *= 0.35 + 0.65 * sqrt(max(c, 0.0));
        // Fade only when projected thickness drops below one physical pixel.
        top *= clamp(c * umbriel_size.y * umbriel_scale / rows, 0.0, 1.0);
        result = reveal_over(top, bottom);
    }
    return result;
}
