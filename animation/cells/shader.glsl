// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Barrulus
float hash21(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * 0.1031);
    q += dot(q, q.yzx + 33.33 + umbriel_random_seed.x);
    return fract((q.x + q.y) * q.z);
}
vec4 overGlow(vec4 base, vec3 tint, float alpha) {
    alpha = clamp(alpha, 0.0, 1.0);
    return vec4(tint * alpha, alpha) + base * (1.0 - alpha);
}

const float CELL_SIZE = 64.0;

vec4 animation(vec2 uv) {
    float t = clamp(umbriel_linear_progress, 0.0, 1.0);
    bool opening = umbriel_direction > 0.0;
    if (t <= 0.0) return opening ? vec4(0.0) : umbriel_sample(uv);
    if (t >= 1.0) return opening ? umbriel_sample(uv) : vec4(0.0);

    // Bisect tiled hexagons through opposite edge midpoints. Each half has
    // exactly five edges; alternating the split direction avoids filler shapes.
    float radius = CELL_SIZE * 0.72;
    vec2 p = (uv - 0.5) * umbriel_size / radius;
    vec2 axial = vec2(p.x * 0.6666667, -p.x / 3.0 + p.y * 0.5773503);
    vec2 base = floor(axial);
    vec2 cell = vec2(0.0), local = vec2(0.0);
    float nearest = 100.0;
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 id = base + vec2(float(x), float(y));
            vec2 center = vec2(1.5 * id.x, 1.7320508 * (id.y + id.x * 0.5));
            vec2 delta = p - center;
            if (dot(delta, delta) < nearest) {
                nearest = dot(delta, delta); local = delta; cell = id;
            }
        }
    }
    float rotation = mod(cell.x + cell.y, 3.0) * 1.0471976;
    vec2 axis = vec2(cos(rotation), sin(rotation));
    float split = dot(local, axis);
    float hexEdge = min(0.8660254 - abs(local.y),
        0.8660254 - dot(abs(local), vec2(0.8660254, 0.5)));
    float edge = min(abs(split), max(hexEdge, 0.0));
    float pixel = 1.0 / radius;
    float line = 1.0 - smoothstep(pixel * 0.6, pixel * 1.8, edge);
    float halo = exp(-edge * 30.0) * 0.3;
    float radial = length((uv - 0.5) * umbriel_size) / max(length(umbriel_size * 0.5), 1.0);
    // Trace outward from the center; erase from the perimeter inward.
    float reach = mix(-0.07, 1.08, smoothstep(0.0, 0.32, t));
    float retreat = mix(1.08, -0.07, smoothstep(0.70, 1.0, t));
    float trace = 1.0 - smoothstep(reach - 0.055, reach + 0.055, radial);
    float erase = 1.0 - smoothstep(retreat - 0.055, retreat + 0.055, radial);
    float delay = hash21(cell + step(0.0, split) * 29.0) * 0.10;
    float fill = smoothstep(0.32 + delay, 0.59 + delay, t);
    vec4 window = umbriel_sample(uv) * (opening ? fill : 1.0 - fill);
    return overGlow(window, mix(vec3(0.07, 0.65, 1.0), vec3(0.6, 1.0, 1.0), line),
        (line + halo) * trace * erase);
}
