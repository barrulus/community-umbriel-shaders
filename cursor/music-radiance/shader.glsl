// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Barrulus
// Ported from bumbriel 1dafcac5; current Umbriel spectrum input.

// Visual activity from all 64 normalized bands; this is not PCM RMS.
const float AUDIO_GAIN = 1.0;
const float NOISE_FLOOR = 0.005;

float audio_intensity(float value) {
    return clamp((value - NOISE_FLOOR) / (1.0 - NOISE_FLOOR) * AUDIO_GAIN, 0.0, 1.0);
}

float audio_activity() {
    float total = 0.0;
    float peak = 0.0;
    for (int i = 0; i < 64; ++i) {
        float value = audio_intensity(umbriel_audio_spectrum(float(i) / 63.0));
        total += value;
        peak = max(peak, value);
    }
    // A narrow spectral peak should still be visible even with a low mean.
    return sqrt(max(total / 64.0, 0.25 * peak));
}

vec4 cursor(vec2 uv) {
    vec4 scene = umbriel_sample(uv);
    if (umbriel_audio_available() < 0.5) return scene;
    float level = audio_activity();
    if (level < 0.001) return scene;
    vec2 p = (uv - umbriel_pointer) * umbriel_size;
    float radius = length(p);
    float angle = atan(p.y, p.x);
    // Sweep the spectrum out and back so both sides of the angle wrap agree.
    float frequency = 0.5 + 0.5 * cos(angle);
    float band = sqrt(audio_intensity(umbriel_audio_spectrum(frequency)));
    float energy = clamp(0.7 * level + 0.3 * band, 0.0, 1.0);
    float phase = radius / (26.0 + 16.0 * energy) - umbriel_time * 0.85;
    float wave = exp(-pow((fract(phase) - 0.5) * 7.0, 2.0));
    float rays = 0.65 + 0.35 * pow(0.5 + 0.5 * cos(angle * 7.0 - radius * 0.035 + umbriel_time), 2.0);
    float falloff = exp(-radius / (45.0 + 65.0 * energy));
    float edge = 1.0 - smoothstep(135.0, 158.0, radius);
    vec3 colour = 0.55 + 0.45 * cos(6.2831853 * (angle / 6.2831853 + radius * 0.004
        - umbriel_time * 0.07 + band * 0.18 + vec3(0.0, 0.33, 0.67)));
    float glow = clamp(energy * (0.22 + 0.95 * wave) * rays * falloff * edge, 0.0, 0.8);
    return vec4(mix(scene.rgb, colour * scene.a, glow), scene.a);
}
