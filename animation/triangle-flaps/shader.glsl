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

const float TILE_SIZE = 85.0;

vec4 animation(vec2 uv) {
    float t = clamp(umbriel_linear_progress, 0.0, 1.0);
    bool opening = umbriel_direction > 0.0;
    if (t <= 0.0) return opening ? vec4(0.0) : umbriel_sample(uv);
    if (t >= 1.0) return opening ? umbriel_sample(uv) : vec4(0.0);

    const float h = 0.8660254;
    vec2 p = uv * umbriel_size / TILE_SIZE;
    vec2 lattice = vec2(p.x - p.y / (2.0 * h), p.y / h);
    vec2 cell = floor(lattice);
    vec4 result = vec4(0.0);
    float pixel = 0.7 / TILE_SIZE;
    // Include neighboring cells because a closing flap falls below its home.
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 id = cell + vec2(float(x), float(y));
            vec2 origin = vec2(id.x + id.y * 0.5, id.y * h);
            for (int k = 0; k < 2; k++) {
                float side = float(k);
                float seed = hash21(id + side * 37.0);
                float delay = 0.43 * seed;
                float phase = clamp((t - delay) / (0.40 + 0.12 * hash21(id + side * 17.0 + 3.0)), 0.0, 1.0);
                // Settled tiles and tiles that have not started are seamless.
                // Assign exact ownership so translucent edge pixels aren't doubled.
                if ((opening && phase >= 1.0) || (!opening && phase <= 0.0)) {
                    vec2 fraction = fract(lattice);
                    float owner = step(1.0, fraction.x + fraction.y);
                    if (all(equal(id, cell)) && side == owner) {
                        vec4 restingColor = umbriel_sample(uv);
                        result = restingColor + result * (1.0 - restingColor.a);
                    }
                    continue;
                }
                float fall = clamp((phase - 0.12) / 0.82, 0.0, 1.0);
                float angle = opening ? 1.48 * (1.0 - fall * fall) : 1.48 * fall * fall;
                float drop = opening ? 0.0 : h * 0.65 * fall * fall;
                float hingeX = side < 0.5 ? 0.5 : 1.0;
                vec2 local = p - origin - vec2(hingeX, drop);
                // Perspective projection around a horizontal hinge: the triangle
                // unfolds downward under acceleration instead of rotating sideways.
                float c = cos(angle), s = sin(angle);
                float denominator = c - local.y * s * 0.20;
                vec4 tile = vec4(0.0);
                if (denominator > 0.015) {
                    float sy = local.y / denominator;
                    float depth = 1.0 + sy * s * 0.20;
                    vec2 source = vec2(local.x * depth + hingeX, sy);
                    float b = source.y / h;
                    float a = source.x - b * 0.5;
                    float edge = side < 0.5 ? min(min(a, b), 1.0 - a - b)
                                            : min(min(1.0 - a, 1.0 - b), a + b - 1.0);
                    float mask = smoothstep(0.0, pixel, edge);
                    if (opening) mask = mix(mask, step(0.0, edge), smoothstep(0.85, 1.0, phase));
                    if (mask > 0.0) {
                        vec4 sampleColor = umbriel_sample((origin + source) * TILE_SIZE / umbriel_size);
                        float appear = opening ? smoothstep(0.06, 0.23, phase) : 1.0;
                        float disappear = opening ? 1.0 : 1.0 - smoothstep(0.52, 1.0, phase);
                        tile = sampleColor;
                        tile.rgb *= 0.42 + 0.58 * c;
                        float outline = (1.0 - smoothstep(pixel, pixel * 3.0, edge))
                            * smoothstep(0.0, 0.12, phase) * (1.0 - smoothstep(0.80, 1.0, phase));
                        tile = overGlow(tile, vec3(0.35, 0.78, 1.0), outline * 0.9);
                        tile *= mask * appear * disappear;
                    }
                }
                // Each tile traces its own flat outline before its flap starts.
                vec2 resting = p - origin;
                float fb = resting.y / h, fa = resting.x - fb * 0.5;
                float fe = side < 0.5 ? min(min(fa, fb), 1.0 - fa - fb)
                                     : min(min(1.0 - fa, 1.0 - fb), fa + fb - 1.0);
                float trace = smoothstep(0.0, 0.07, phase) * (1.0 - smoothstep(0.15, 0.35, phase));
                float line = (1.0 - smoothstep(pixel, pixel * 2.5, abs(fe))) * trace;
                tile = overGlow(tile, vec3(0.35, 0.78, 1.0), line * 0.8);
                result = tile + result * (1.0 - tile.a);
            }
        }
    }
    // Remove subpixel tessellation seams at the fully visible endpoint.
    if (opening) return mix(result, umbriel_sample(uv), smoothstep(0.94, 1.0, t));
    return mix(umbriel_sample(uv), result, smoothstep(0.0, 0.055, t));
}
