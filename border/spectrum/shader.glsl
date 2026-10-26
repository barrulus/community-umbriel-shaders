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

vec4 border(vec2 uv) {
    vec4 native = umbriel_sample(uv);
    if (umbriel_audio_available() < 0.5) return native;
    float position = (atan(uv.y - 0.5, uv.x - 0.5) + 3.14159265) / 6.2831853;
    float band = sqrt(audio_intensity(umbriel_audio_spectrum(position)));
    float level = audio_activity();
    float strength = clamp(0.6 * band + 0.4 * level, 0.0, 1.0);
    float distance = max(umbriel_border_distance(uv), 0.0);
    vec4 tint = umbriel_palette_count > 0 ? umbriel_palette_at(fract(position + 0.25 * level)) : vec4(0.25, 0.65, 1.0, 1.0);
    float halo = 0.9 * exp(-distance / (6.0 + 18.0 * strength));
    halo *= 1.0 - smoothstep(18.0, 24.0, distance);
    float alpha = strength * max(native.a, halo);
    return native * (1.0 - strength) + vec4(tint.rgb * tint.a, tint.a) * alpha;
}
