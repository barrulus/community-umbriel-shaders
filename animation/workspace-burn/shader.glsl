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

vec4 animation(vec2 uv) {
    float p = umbriel_clamped_progress;
    if (p <= 0.0) return umbriel_sample(uv);
    if (p >= 1.0) return umbriel_sample_incoming(uv);
    vec2 q = uv * vec2(umbriel_size.x / umbriel_size.y, 1.0);
    // A coherent, predominantly directional front, not independent pixel death.
    float noise = 0.58 * reveal_noise(q * 5.0)
        + 0.28 * reveal_noise(q * 11.0 + 23.0)
        + 0.14 * reveal_noise(q * 25.0 + 51.0);
    float field = 0.72 * reveal_along(uv) + 0.28 * noise;
    float edge = field - mix(-0.04, 1.04, p);
    vec4 bottom = umbriel_sample_incoming(uv);
    if (edge <= 0.0) return bottom;
    vec4 top = umbriel_sample(uv);
    // Thin hot rim, then broader black char, then untouched desktop.
    float charred = smoothstep(0.007, 0.036, edge);
    top.rgb *= mix(0.10, 1.0, charred);
    float hot = (1.0 - smoothstep(0.002, 0.009, edge));
    top.rgb += vec3(1.5, 0.52, 0.08) * hot * top.a;
    float coverage = smoothstep(0.0, 0.0015, edge);
    return reveal_over(top * coverage, bottom);
}
