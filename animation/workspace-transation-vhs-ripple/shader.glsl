// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Barrulus
// Runs over the combined workspace view during the compositor's normal slide.
// Linear progress keeps the pulse independent of spring overshoot and direction.
vec4 animation(vec2 uv) {
    float p = clamp(umbriel_linear_progress, 0.0, 1.0);
    if (p <= 0.0 || p >= 1.0) return umbriel_sample(uv);

    // Smooth onset and finish; keep the image opaque throughout the transition.
    float envelope = 16.0 * p * p * (1.0 - p) * (1.0 - p);
    vec2 edge = 4.0 * uv * (1.0 - uv);
    float phase = 6.2831853 * p;
    vec2 wave = vec2(sin(6.2831853 * uv.y - phase),
                     sin(6.2831853 * uv.x - phase));
    // Fade displacement at every edge to avoid sampling beyond the capture.
    vec2 displaced = uv + 0.030 * envelope * edge.x * edge.y * wave;

    // A rolling tracking band and coarse line jitter, driven by the event clock.
    float tick = floor(p * 24.0);
    float row = floor(uv.y * 180.0);
    float noise = fract(sin(row * 127.1 + tick * 311.7) * 43758.5453);
    float band = 1.0 - smoothstep(0.0, 0.09, abs(uv.y - mix(-0.1, 1.1, p)));
    displaced.x += envelope * edge.x * edge.y
        * (0.080 * band + 0.015 * (noise - 0.5));
    displaced = clamp(displaced, vec2(0.0), vec2(1.0));

    // Strong chroma misregistration; retain the central sample's coverage.
    float split = envelope * edge.x * (0.006 + 0.012 * band);
    vec4 center = umbriel_sample(displaced);
    vec4 red = umbriel_sample(clamp(displaced + vec2(split, 0.0), vec2(0.0), vec2(1.0)));
    vec4 blue = umbriel_sample(clamp(displaced - vec2(split, 0.0), vec2(0.0), vec2(1.0)));
    vec3 color = center.rgb / max(center.a, 0.0001);
    color.r = mix(color.r, red.r / max(red.a, 0.0001), envelope);
    color.b = mix(color.b, blue.b / max(blue.a, 0.0001), envelope);

    float scanline = 0.5 + 0.5 * sin(uv.y * umbriel_size.y * 3.14159265);
    color *= 1.0 - envelope * (0.14 * scanline + 0.22 * band);
    color += envelope * (0.065 * (noise - 0.5));
    return vec4(clamp(color, vec3(0.0), vec3(1.0)) * center.a, center.a);
}
