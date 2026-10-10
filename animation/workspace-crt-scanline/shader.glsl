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
    float y = workspace_sign() < 0.0 ? 1.0 - uv.y : uv.y;
    float distance = y - mix(-0.045, 1.045, p);
    vec4 bottom = umbriel_sample_incoming(uv);
    if (distance < -0.004) return bottom;
    if (distance > 0.032) return umbriel_sample(uv);
    float band = 1.0 - smoothstep(0.003, 0.032, abs(distance));
    // Deliberate electronic noise: quantized progress, never wall-clock time.
    float tick = floor(p * 90.0);
    float line = floor(uv.y * umbriel_size.y * umbriel_scale);
    float jitter = reveal_hash(vec2(floor(line / 3.0), tick));
    float burst = step(0.90, reveal_hash(vec2(floor(line / 9.0), tick)));
    float offset = band * ((jitter - 0.5) * 0.008 + burst * (jitter - 0.5) * 0.045);
    float separation = band * (0.0015 + burst * 0.003);
    vec2 source = uv + vec2(offset, 0.0);
    vec4 red = umbriel_sample(clamp(source + vec2(separation, 0.0), 0.0, 1.0));
    vec4 green = umbriel_sample(clamp(source, 0.0, 1.0));
    vec4 blue = umbriel_sample(clamp(source - vec2(separation, 0.0), 0.0, 1.0));
    vec4 top = vec4(red.r, green.g, blue.b, max(red.a, max(green.a, blue.a)));
    float scan = mod(line, 2.0);
    float noise = reveal_hash(vec2(floor(uv.x * umbriel_size.x / 2.0) + tick * 17.0, line));
    top.rgb *= 1.0 - band * (0.22 * scan + 0.12 * noise);
    top.rgb += vec3(0.10, 0.18, 0.21) * band * noise * top.a;
    float coverage = smoothstep(-0.001, 0.001, distance);
    vec4 result = reveal_over(top * coverage, bottom);
    float beam = 1.0 - smoothstep(0.0, 0.003, abs(distance));
    result.rgb += vec3(0.20, 0.40, 0.48) * beam * result.a;
    return result;
}
