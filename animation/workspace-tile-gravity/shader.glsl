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

// Rigid tiles: gather possible source rows, then inverse-transform each tile.
// No grid lines or gaps exist until a tile actually releases.
vec4 animation(vec2 uv) {
    float p = umbriel_clamped_progress;
    if (p <= 0.0) return umbriel_sample(uv);
    if (p >= 1.0) return umbriel_sample_incoming(uv);
    float aspect = umbriel_size.x / umbriel_size.y;
    float columns = clamp(floor(18.0 * aspect + 0.5), 24.0, 40.0);
    vec2 grid = vec2(columns, clamp(floor(columns / aspect + 0.5), 12.0, 48.0));
    // Square physical coordinates, including on portrait/ultrawide outputs.
    vec2 cell = vec2(aspect, 1.0) / grid;
    vec2 point = uv * vec2(aspect, 1.0);
    vec4 bottom = umbriel_sample_incoming(uv), result = bottom;
    for (int row = 0; row < 48; row++) {
        if (float(row) >= grid.y || float(row) > uv.y * grid.y + 1.0) break;
        for (int col = -1; col <= 1; col++) {
            vec2 id = vec2(floor(uv.x * grid.x) + float(col), float(row));
            if (id.x < 0.0 || id.x >= grid.x) continue;
            vec2 rnd = reveal_random(id);
            float release = 0.02 + 0.19 * (1.0 - (id.y + 0.5) / grid.y)
                + 0.10 * rnd.x + 0.025 * reveal_along((id + 0.5) / grid);
            float t = max(0.0, (p - release) / (1.0 - release));
            vec2 travel = vec2((rnd.x - 0.5) * 0.36 * cell.x * t * reveal_sign(),
                0.08 * t + (1.6 + 0.6 * rnd.y) * t * t);
            vec2 center = (id + 0.5) * cell;
            vec2 local = reveal_rotation(-(rnd.y - 0.5) * 0.65 * t) * (point - center - travel);
            if (any(greaterThanEqual(abs(local), cell * 0.5))) continue;
            vec4 top = umbriel_sample((center + local) / vec2(aspect, 1.0));
            top.rgb *= 1.0 - 0.10 * t;
            result = reveal_over(top, bottom);
        }
    }
    return result;
}
