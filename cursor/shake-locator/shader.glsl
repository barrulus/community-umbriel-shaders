// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Barrulus
// Shake-to-locate: motion history is the only animation clock.
// Distances are logical pixels, durations are seconds.
const float kMinStep = 3.0;
const float kMinSpeed = 180.0;
const float kMinLeg = 24.0;
const float kMaxTurnGap = 0.32;
const float kTurnDot = -0.4;
const float kFade = 0.60;
const float kRingSize = 1.0;
const vec3 kInnerColour = vec3(0.35, 0.95, 1.0);
const vec3 kOuterColour = vec3(1.0, 0.83, 0.30);

float shakeEnvelope() {
    vec4 previous = vec4(0.0);
    vec2 direction = vec2(0.0);
    float leg = 0.0;
    float lastTurnAge = 10.0;
    float strength = 0.0;
    // Two substantial, fast reversals close together are a shake. A single
    // fast sweep, small jitter, and smooth circular travel do not qualify.
    for (int i = 0; i < 64; ++i) {
        if (i < umbriel_pointer_count) {
            vec4 point = umbriel_pointer_path[i];
            if (i > 0) {
                vec2 delta = (point.xy - previous.xy) * umbriel_size;
                float distance = length(delta);
                float dt = max(previous.z - point.z, 0.001);
                if (dt > 0.12) {
                    direction = vec2(0.0);
                    leg = 0.0;
                    lastTurnAge = 10.0;
                }
                if (distance >= kMinStep && distance / dt >= kMinSpeed) {
                    vec2 nextDirection = delta / distance;
                    if (dot(direction, nextDirection) < kTurnDot) {
                        if (leg >= kMinLeg) {
                            if (lastTurnAge - point.z < kMaxTurnGap) {
                                float attack = smoothstep(0.0, 0.045, point.z);
                                float decay = 1.0 - smoothstep(0.10, kFade, point.z);
                                strength = max(strength, attack * decay);
                            }
                            lastTurnAge = point.z;
                        } else {
                            lastTurnAge = 10.0;
                        }
                        leg = 0.0;
                    }
                    leg += distance;
                    direction = nextDirection;
                }
            }
            previous = point;
        }
    }
    return strength;
}

vec4 cursor(vec2 uv) {
    vec4 source = umbriel_sample(uv);
    float radius = length((uv - umbriel_pointer) * umbriel_size) / kRingSize;
    // History expands the draw rectangle. Skip detection away from the rings.
    if (radius < 24.0 || radius > 116.0) {
        return source;
    }
    float strength = shakeEnvelope();
    if (strength <= 0.0) {
        return source;
    }
    float expansion = 9.0 * (1.0 - strength);
    float inner = abs(radius - (37.0 + expansion));
    float middle = abs(radius - (64.0 + expansion));
    float outer = abs(radius - (91.0 + expansion));
    float distance = min(inner, min(middle, outer));
    float aa = max(0.7, 1.0 / (umbriel_scale * kRingSize));
    float ink = 1.0 - smoothstep(4.0, 4.0 + aa, distance);
    float line = 1.0 - smoothstep(1.6, 1.6 + aa, distance);
    float glow = exp(-distance * distance / 38.0) * 0.24;
    vec3 colour = mix(kInnerColour, kOuterColour, smoothstep(43.0, 92.0, radius));
    // Source-over keeps premultiplied alpha valid, including transparent input.
    float shadowAlpha = ink * strength * 0.9;
    vec4 shaded = source * (1.0 - shadowAlpha) + vec4(vec3(0.015) * shadowAlpha, shadowAlpha);
    float lightAlpha = max(line, glow) * strength;
    return shaded * (1.0 - lightAlpha) + vec4(colour * lightAlpha, lightAlpha);
}
