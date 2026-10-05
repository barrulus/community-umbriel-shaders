// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Barrulus
float hash21(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * 0.1031);
    q += dot(q, q.yzx + 33.33 + umbriel_random_seed.x);
    return fract((q.x + q.y) * q.z);
}

const float TRACKING_SHIFT = 0.19;

vec4 animation(vec2 uv) {
    float t = clamp(umbriel_linear_progress, 0.0, 1.0);
    bool opening = umbriel_direction > 0.0;
    if (t <= 0.0) return opening ? vec4(0.0) : umbriel_sample(uv);
    if (t >= 1.0) return opening ? umbriel_sample(uv) : vec4(0.0);

    float visible = opening ? t : 1.0 - t;
    float strength = 1.0 - smoothstep(0.10, 1.0, visible);
    float tick = floor(t * 45.0);
    float trackingY = fract(t * 1.9 + umbriel_random_seed.y);
    float tracking = exp(-abs(uv.y - trackingY) * 35.0);
    float row = floor(uv.y * max(umbriel_size.y, 1.0) / 3.0);
    float jitter = (hash21(vec2(row, tick)) - 0.5) * 0.024;
    float bend = sin(uv.y * 12.0 + t * 25.0) * 0.035;
    float shift = (bend + jitter + tracking * TRACKING_SHIFT) * strength;
    vec2 source = vec2((uv.x - 0.5) / (1.0 + tracking * strength * 0.8) + 0.5 + shift, uv.y);
    float split = (0.006 + tracking * 0.025) * strength;
    vec4 base = umbriel_sample(source);
    vec4 red = umbriel_sample(source + vec2(split, 0.0));
    vec4 blue = umbriel_sample(source - vec2(split, 0.0));
    float alpha = max(base.a, max(red.a, blue.a));
    vec4 tape = vec4(red.r, base.g, blue.b, alpha);
    float scanline = 0.5 + 0.5 * sin(uv.y * umbriel_size.y * 3.14159);
    tape.rgb *= 1.0 - scanline * strength * 0.22;
    float snow = hash21(vec2(floor(uv.x * umbriel_size.x / 2.0), row) + tick);
    tape.rgb = mix(tape.rgb, vec3(snow) * alpha, (0.09 + tracking * 0.5) * strength);
    return tape * smoothstep(0.0, 0.65, visible);
}
