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

// Thousands of rigid grains, with no stretched source coordinates. Inverting
// the monotone ballistic stream locates at most three source rows per band;
// cost stays 27 candidates per pixel regardless of grain count/resolution.
vec4 animation(vec2 uv) {
    float p = umbriel_clamped_progress;
    if (p <= 0.0) return umbriel_sample(uv);
    if (p >= 1.0) return umbriel_sample_incoming(uv);
    float rows = clamp(floor(umbriel_size.y / 3.0), 90.0, 360.0);
    vec2 grid = vec2(ceil(rows * umbriel_size.x / umbriel_size.y), rows);
    vec4 bottom = umbriel_sample_incoming(uv), result = bottom;
    for (int column = -1; column <= 1; column++) {
        float x = floor(uv.x * grid.x) + float(column);
        if (x < 0.0 || x >= grid.x) continue;
        float stream = reveal_hash(vec2(x, 91.0));
        float gravity = 6.8 + 1.2 * stream;
        for (int band = 0; band < 3; band++) {
            // Broad noisy failure pockets superimposed on bottom-first release.
            float origin_x = workspace_sign() < 0.0 ? grid.x - 1.0 - x : x;
            float start = 0.35 + 0.12 * reveal_noise(vec2(origin_x / 13.0, float(band) * 5.0))
                + 0.025 * stream;
            float slope = 0.28;
            float d = p - start + slope * uv.y;
            float t = d > 0.0 ? 2.0 * d / (1.0 + sqrt(1.0 + 4.0 * slope * gravity * d)) : 0.0;
            float source_row = floor((uv.y - gravity * t * t) * rows);
            for (int neighbour = -1; neighbour <= 1; neighbour++) {
                vec2 id = vec2(x, source_row + float(neighbour));
                if (id.y < 0.0 || id.y >= rows || floor(3.0 * (id.y + 0.5) / rows) != float(band)) continue;
                vec2 rnd = reveal_random(id + 117.0);
                vec2 center = (id + 0.5) / grid;
                float release = start - slope * center.y + (rnd.y - 0.5) * 0.18 / rows;
                float age = max(0.0, p - release);
                vec2 travel = vec2((rnd.x - 0.5) * 0.8 * age / grid.x * reveal_sign(), gravity * age * age);
                vec2 local = (uv - center - travel) * grid;
                // Open dry gaps as each grain releases; no liquid smearing.
                float half_size = mix(0.5, 0.34 + 0.09 * rnd.y, smoothstep(0.0, 0.045, age));
                if (any(greaterThanEqual(abs(local), vec2(half_size)))) continue;
                vec2 source = age > 0.0 ? center : uv;
                vec4 top = umbriel_sample(source);
                top.rgb *= 1.0 - 0.12 * smoothstep(0.0, 0.12, age) * rnd.x;
                result = reveal_over(top, bottom);
            }
        }
    }
    return result;
}
