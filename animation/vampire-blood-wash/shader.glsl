// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Barrulus
// Vampire family: a glossy blood wash over two complete workspace scenes.
uniform vec2 umbriel_workspace_axis;

const float WASH_WIDTH = 0.30; // Fraction of the diagonal sweep range.
const float RIVULET_LENGTH = 0.075;
const float REFRACTION = 3.0; // Logical pixels beneath the wet leading lip.
const vec3 BLOOD_DEEP = vec3(0.095, 0.003, 0.012);
const vec3 BLOOD_RED = vec3(0.56, 0.008, 0.025);
const vec3 WET_HIGHLIGHT = vec3(0.90, 0.24, 0.27);

float blood_hash(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973)
        + umbriel_random_seed.xyz);
    q += dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z);
}

float blood_noise(vec2 p) {
    vec2 cell = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(blood_hash(cell), blood_hash(cell + vec2(1.0, 0.0)), f.x),
        mix(blood_hash(cell + vec2(0.0, 1.0)), blood_hash(cell + vec2(1.0)), f.x), f.y);
}

vec4 animation(vec2 uv) {
    float p = umbriel_clamped_progress;
    if (p <= 0.0) return umbriel_sample(uv);
    if (p >= 1.0) return umbriel_sample_incoming(uv);

    // Down: top-left -> bottom-right. Up: bottom-left -> top-right.
    // Both keep left-to-right travel; only the vertical coordinate reflects.
    bool upwards = umbriel_workspace_axis.x + umbriel_workspace_axis.y < 0.0;
    vec2 sweep = vec2(uv.x, upwards ? 1.0 - uv.y : uv.y);
    vec2 size = max(umbriel_size, vec2(1.0));
    vec2 pixel = sweep * size;
    float diagonal = size.x + size.y;
    float unit = min(size.x, size.y);
    float along = (pixel.x + pixel.y) / diagonal;
    float across = (pixel.x - pixel.y) / unit;

    // Held rivulets give the advancing edge long rounded tongues. Geometry
    // depends on position and seed, so the reveal never flickers between frames.
    float broad = blood_noise(vec2(across * 5.0, 3.7));
    float fine = blood_noise(vec2(across * 13.0, 17.2));
    float fingers = pow(clamp(0.70 * broad + 0.30 * fine, 0.0, 1.0), 2.0);
    float length = clamp(RIVULET_LENGTH, 0.0, 0.18);
    float field = along - length * fingers
        + 0.012 * blood_noise(sweep * 8.0);
    float width = clamp(WASH_WIDTH, 0.12, 0.55);
    float padding = length + 0.025;
    float front = mix(-padding, 1.0 + width + padding, p);
    float age = front - field;
    float aa = 1.5 / (diagonal * max(umbriel_scale, 0.001));
    float wet = smoothstep(-aa, aa, age);
    float drain = smoothstep(width * 0.60, width, age);
    float blood = wet * (1.0 - drain);
    // Replace the scene at the leading edge, while the blood conceals it.
    // Delaying this until the blood drains exposes the outgoing scene again.
    float reveal = wet;

    // Refraction is confined to the leading meniscus and fades at output edges.
    float lip = 1.0 - smoothstep(0.0, 0.018, abs(age));
    vec2 safeEdge = 4.0 * uv * (1.0 - uv);
    vec2 direction = vec2(1.0, upwards ? -1.0 : 1.0) * 0.70710678;
    vec2 refracted = uv + direction * max(REFRACTION, 0.0) / size
        * lip * safeEdge.x * safeEdge.y;
    refracted = clamp(refracted, vec2(0.0), vec2(1.0));
    vec4 scene = mix(umbriel_sample(refracted), umbriel_sample_incoming(refracted), reveal);

    // Deep wine shadows, crimson body, fine flowing streaks and a wet rim.
    float flow = blood_noise(vec2(across * 16.0, along * 2.4 - p * 2.0));
    float body = 0.35 + 0.45 * broad + 0.20 * flow;
    vec3 color = mix(BLOOD_DEEP, BLOOD_RED, body);
    float ridge = pow(clamp(flow, 0.0, 1.0), 5.0);
    color *= 0.72 + 0.28 * smoothstep(0.0, width * 0.16, age);
    float glint = (1.0 - smoothstep(aa, max(0.006, 2.0 * aa), abs(age - 0.005))) * wet;
    color = mix(color, WET_HIGHLIGHT, 0.48 * glint + 0.12 * ridge);
    // Tinting a premultiplied scene preserves alpha and covers its wallpaper too.
    scene.rgb = mix(scene.rgb, color * scene.a, blood);
    return scene;
}
