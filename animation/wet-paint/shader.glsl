// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Barrulus
float hash21(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * 0.1031);
    q += dot(q, q.yzx + 33.33 + umbriel_random_seed.x);
    return fract((q.x + q.y) * q.z);
}
float noise21(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
               mix(hash21(i + vec2(0.0, 1.0)), hash21(i + 1.0), f.x), f.y);
}

const float STREAM_WIDTH = 58.0;
const float DRIP_LENGTH = 0.52;

vec4 animation(vec2 uv) {
    float t = clamp(umbriel_linear_progress, 0.0, 1.0);
    bool opening = umbriel_direction > 0.0;
    if (t <= 0.0) return opening ? vec4(0.0) : umbriel_sample(uv);
    if (t >= 1.0) return opening ? umbriel_sample(uv) : vec4(0.0);

    float columns = clamp(umbriel_size.x / STREAM_WIDTH, 5.0, 30.0);
    float x = uv.x * columns;
    float stream = noise21(vec2(x * 0.72, 2.0));
    float envelope = sin(t * 3.14159);
    float fingers = 0.0;
    // Unequal rounded streams. Neighbor search avoids visible cell boundaries.
    for (int k = -1; k <= 1; k++) {
        float id = floor(x) + float(k);
        float seed = hash21(vec2(id, 13.0));
        float center = id + 0.2 + seed * 0.6;
        float width = 0.17 + hash21(vec2(id, 44.0)) * 0.22;
        float crossSection = exp(-pow(abs(x - center) / width, 4.0));
        fingers = max(fingers, crossSection * (0.35 + 0.65 * seed));
    }
    float base = mix(-0.38, 1.38, t);
    float front = base + ((stream - 0.5) * 0.15 + fingers * DRIP_LENGTH) * envelope;
    float distance = uv.y - front;
    // Opening lays paint down; closing pulls the top edge down at unequal rates.
    float mask = opening ? 1.0 - smoothstep(-0.010, 0.010, distance)
                         : smoothstep(-0.010, 0.010, distance);
    float wet = exp(-abs(distance) * 3.2) * envelope;
    vec2 source = uv;
    // Stretch the paint downward without pulling samples above the top edge;
    // otherwise the incoming streams would become detached floating droplets.
    source.y /= 1.0 + (0.70 + 0.60 * fingers) * wet;
    source.x += sin(uv.y * 8.0 + x) * 0.01 * wet;
    vec4 paint = umbriel_sample(source);
    paint.rgb *= 1.0 - 0.22 * wet;
    float shine = exp(-abs(distance + (opening ? 0.012 : -0.012)) * 70.0) * envelope;
    paint.rgb = mix(paint.rgb, paint.a * vec3(0.85, 0.95, 1.0), shine * 0.48);
    return paint * mask;
}
