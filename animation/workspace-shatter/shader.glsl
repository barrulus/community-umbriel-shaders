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

// Inverse-rasterize rigid Voronoi shards. All motion is in square cell units;
// the destination is never transformed. Bounded gather: 6 rows x 5 columns.
vec2 shard_site(vec2 id) { return id + 0.5 + (reveal_random(id) - 0.5) * 0.55; }
vec4 animation(vec2 uv) {
    float p = umbriel_clamped_progress;
    if (p <= 0.0) return umbriel_sample(uv);
    if (p >= 1.0) return umbriel_sample_incoming(uv);
    vec2 grid = vec2(6.0 * umbriel_size.x / umbriel_size.y, 6.0);
    vec2 point = uv * grid;
    vec4 result = umbriel_sample_incoming(uv);
    float best = -1.0;
    for (int row = 0; row < 6; row++) {
        for (int col = -2; col <= 2; col++) {
            vec2 id = vec2(floor(point.x) + float(col), float(row));
            if (id.x < 0.0 || id.x >= ceil(grid.x)) continue;
            vec2 site = shard_site(id);
            vec2 rnd = reveal_random(id + 71.0);
            float origin = reveal_along(site / grid);
            float release = 0.055 + 0.085 * origin + 0.055 * rnd.x;
            float t = max(0.0, (p - release) / (1.0 - release));
            // Maximum sideways travel < .7 cells; rotated radius < 1.5.
            vec2 travel = vec2((rnd.x - 0.5) * 1.3 * t * reveal_sign(),
                (8.8 + 2.0 * rnd.y) * t * t);
            vec2 local = reveal_rotation(-(rnd.y - 0.5) * 2.4 * t) * (point - site - travel);
            if (dot(local, local) > 2.25) continue;
            vec2 source = site + local;
            if (any(lessThan(source, vec2(0.0))) || any(greaterThan(source, grid))) continue;
            float edge = 10.0;
            // Jitter is bounded to .275: adjacent sites define every cell.
            for (int y = -1; y <= 1; y++) {
                for (int x = -1; x <= 1; x++) {
                    if (x == 0 && y == 0) continue;
                    vec2 neighbour = id + vec2(float(x), float(y));
                    if (any(lessThan(neighbour, vec2(0.0))) || any(greaterThanEqual(neighbour, ceil(grid)))) continue;
                    vec2 other = shard_site(neighbour) - site;
                    edge = min(edge, (dot(other, other) * 0.5 - dot(local, other)) / length(other));
                }
            }
            float crack = 0.018 * smoothstep(0.0, 0.045, p - 0.035 * origin);
            float coverage = smoothstep(crack, crack + 0.7 * grid.y / (umbriel_size.y * umbriel_scale), edge);
            if (coverage <= 0.0) continue;
            // A stable per-shard depth resolves overlaps, independent of frames.
            float depth = rnd.y + float(row) * 0.01;
            if (depth > best) {
                vec4 top = umbriel_sample(source / grid);
                top.rgb *= 1.0 - 0.18 * t;
                result = reveal_over(top * coverage, umbriel_sample_incoming(uv));
                best = depth;
            }
        }
    }
    return result;
}
