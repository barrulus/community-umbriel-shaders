// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Barrulus
// Spectrum-driven speaker ripples: peaks push inward, falling levels recoil.

const float AUDIO_GAIN = 1.0;
const float NOISE_FLOOR = 0.005;
const float REACH = 170.0;          // Maximum inward reach, logical pixels.
const float WAVELENGTH = 32.0;      // Logical pixels between pressure rings.
const float JUMP_DISTANCE = 90.0;   // Full-scale audio excursion, logical pixels.
const float DISPLACEMENT = 3.0;     // Maximum content vibration, logical pixels.
const float COLOUR_STRENGTH = 0.62;
const float CORNER_SOFTNESS = 18.0; // Rounds the meeting of adjacent waves.
const float TAU = 6.2831853;

float speaker_intensity(float value) {
    return clamp((value - NOISE_FLOOR) * AUDIO_GAIN / (1.0 - NOISE_FLOOR), 0.0, 1.0);
}

vec3 speaker_bands() {
    vec3 total = vec3(0.0);
    vec3 peak = vec3(0.0);
    // Scan every band so narrow peaks cannot fall between sampled positions.
    for (int i = 0; i < 64; ++i) {
        float value = speaker_intensity(umbriel_audio_spectrum(float(i) / 63.0));
        if (i < 16) {
            total.x += value;
            peak.x = max(peak.x, value);
        } else if (i < 40) {
            total.y += value;
            peak.y = max(peak.y, value);
        } else {
            total.z += value;
            peak.z = max(peak.z, value);
        }
    }
    return max(total / vec3(16.0, 24.0, 24.0), peak * 0.25);
}

vec4 window(vec2 uv) {
    vec4 source = umbriel_sample(uv);
    if (umbriel_audio_available() < 0.5) return source;
    vec3 bands = speaker_bands();
    float energy = sqrt(max(bands.x, max(bands.y, bands.z)));
    if (energy < 0.001) return source;

    vec2 size = max(umbriel_size, vec2(1.0));
    vec2 p = (uv - 0.5) * size;
    vec2 edge = 0.5 * size - abs(p);
    // Smooth minimum and its gradient: rounded rectangular wavefronts,
    // without an abrupt change in distortion direction at the diagonals.
    float rounding = min(CORNER_SOFTNESS, min(size.x, size.y) * 0.08);
    float delta = edge.x - edge.y;
    float diagonal = sqrt(delta * delta + rounding * rounding);
    float distance = max(0.0, 0.5 * (edge.x + edge.y - diagonal));
    vec2 weights = vec2(0.5 - 0.5 * delta / diagonal,
                        0.5 + 0.5 * delta / diagonal);
    vec2 inward = -sign(p) * weights;
    float reach = min(REACH, min(size.x, size.y) * 0.44) * (0.35 + 0.65 * energy);
    float envelope = exp(-distance / (reach * 0.65))
        * (1.0 - smoothstep(reach * 0.65, reach, distance));
    if (envelope < 0.0001) return source;

    // Mirror the spectrum around the perimeter without an angular wrap seam.
    // Bass pushes the whole surround; individual bands buckle its wavefronts.
    float frequency = 0.5 + 0.5 * p.x / max(length(p), 0.001);
    float localBand = speaker_intensity(umbriel_audio_spectrum(frequency));
    float pressure = 0.55 * bands.x + 0.30 * localBand + 0.10 * bands.y + 0.05 * bands.z;
    float excursion = min(JUMP_DISTANCE, min(size.x, size.y) * 0.30);
    // Positions follow current audio directly, with no autonomous travel clock.
    // Rising levels kick crests inward; drops pull them back toward the edge.
    float phase = TAU * (distance - excursion * pressure) / WAVELENGTH;
    float detailPhase = TAU * (distance - excursion * (0.65 * localBand
        + 0.25 * bands.y + 0.10 * bands.z)) / (WAVELENGTH * 0.5) + 0.8;
    float bassWave = sin(phase);
    float detailWave = sin(detailPhase);
    float vibration = ((0.65 * bands.x + 0.35 * localBand) * bassWave + 0.3 * bands.y * detailWave
        + 0.12 * bands.z * sin(phase * 3.0)) / 1.42;
    float edgeGuard = smoothstep(0.0, DISPLACEMENT * 2.0 + 1.0, distance);
    vec2 offset = inward * vibration * DISPLACEMENT * envelope * edgeGuard / size;
    vec4 warped = umbriel_sample(clamp(uv + offset, vec2(0.0), vec2(1.0)));
    // Keep the original coverage, including transparent animation captures.
    vec3 content = warped.a > 0.0001 ? warped.rgb * (source.a / warped.a) : source.rgb;

    float crest = pow(0.5 + 0.5 * cos(phase), 7.0);
    float overtone = pow(0.5 + 0.5 * cos(detailPhase), 12.0);
    float rim = exp(-distance / 3.0);
    float spectralHue = (0.04 * bands.x + 0.38 * bands.y + 0.72 * bands.z)
        / max(bands.x + bands.y + bands.z, 0.001);
    float hue = spectralHue + distance / WAVELENGTH * 0.10 + localBand * 0.22;
    vec3 colour = 0.54 + 0.46 * cos(TAU * (hue + vec3(0.0, 0.33, 0.67)));
    if (umbriel_palette_count > 0) colour = umbriel_palette_at(hue).rgb;
    colour = mix(colour, vec3(1.0), 0.18 * bands.z * crest);
    float localEnergy = sqrt(localBand);
    float glow = COLOUR_STRENGTH * envelope * ((0.65 * energy + 0.35 * localEnergy)
        * (0.08 + 0.90 * crest + 0.20 * rim) + 0.25 * max(bands.y, bands.z) * overtone);
    return vec4(mix(content, colour * source.a, clamp(glow, 0.0, 0.85)), source.a);
}
