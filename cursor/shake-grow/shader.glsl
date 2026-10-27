// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Barrulus
// Growing arrow UNDER the real pointer; not cursor-image scaling.
// Motion history drives activation, accumulated growth, and return to rest.
const float kMinStep = 3.0;
const float kMinSpeed = 180.0;
const float kMinLeg = 24.0;
const float kMaxTurnGap = 0.32;
const float kTurnDot = -0.4;
const float kHold = 0.35;
const float kFade = 0.80;
const float kStartScale = 1.45;
const float kGrowthPerTurn = 1.50;
const float kMaxScale = 18.0;
const vec3 kFill = vec3(0.91, 0.98, 1.0);
const vec3 kAccent = vec3(0.20, 0.85, 1.0);

vec2 shakeGrowth() {
    vec4 previous = vec4(0.0);
    vec2 direction = vec2(0.0);
    float leg = 0.0;
    float lastTurnAge = 10.0;
    float strength = 0.0;
    float shakes = 0.0;
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
                                float decay = 1.0 - smoothstep(kHold, kFade, point.z);
                                strength = max(strength, attack * decay);
                                // Count recent shakes, easing each new size increment.
                                // Taper old events before the two-second path expires.
                                shakes += smoothstep(0.0, 0.09, point.z)
                                    * (1.0 - smoothstep(1.45, 1.80, point.z));
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
    return vec2(strength, shakes);
}

void arrowEdge(vec2 p, vec2 a, vec2 b, inout float distance2, inout float side) {
    vec2 edge = b - a;
    vec2 rel = p - a;
    vec2 nearest = rel - edge * clamp(dot(rel, edge) / dot(edge, edge), 0.0, 1.0);
    distance2 = min(distance2, dot(nearest, nearest));
    if ((a.y > p.y) != (b.y > p.y)) {
        if (p.x < a.x + (p.y - a.y) * edge.x / edge.y) {
            side = -side;
        }
    }
}

float arrowDistance(vec2 p) {
    float distance2 = 100000.0;
    float side = 1.0;
    // Tip stays at the pointer hotspot as the arrow grows down and right.
    arrowEdge(p, vec2(0.0, 0.0), vec2(0.0, 25.0), distance2, side);
    arrowEdge(p, vec2(0.0, 25.0), vec2(6.6, 19.0), distance2, side);
    arrowEdge(p, vec2(6.6, 19.0), vec2(11.0, 29.0), distance2, side);
    arrowEdge(p, vec2(11.0, 29.0), vec2(15.0, 27.0), distance2, side);
    arrowEdge(p, vec2(15.0, 27.0), vec2(10.5, 17.0), distance2, side);
    arrowEdge(p, vec2(10.5, 17.0), vec2(19.0, 17.0), distance2, side);
    arrowEdge(p, vec2(19.0, 17.0), vec2(0.0, 0.0), distance2, side);
    return sqrt(distance2) * side;
}

vec4 cursor(vec2 uv) {
    vec4 source = umbriel_sample(uv);
    vec2 offset = (uv - umbriel_pointer) * umbriel_size;
    // Early rejection keeps the 64-sample scan local even after long travel.
    if (offset.x < -3.0 * kMaxScale || offset.y < -3.0 * kMaxScale
        || offset.x > 23.0 * kMaxScale || offset.y > 33.0 * kMaxScale) {
        return source;
    }
    vec2 growth = shakeGrowth();
    float visibility = growth.x;
    if (visibility <= 0.0) {
        return source;
    }
    float grownScale = min(kMaxScale, kStartScale + kGrowthPerTurn * growth.y);
    float scale = mix(1.0, grownScale, visibility);
    vec2 local = offset / scale;
    float distance = arrowDistance(local);
    float aa = max(0.08, 1.0 / (umbriel_scale * scale));
    float outline = 1.0 - smoothstep(1.1, 1.1 + aa, distance);
    float fill = 1.0 - smoothstep(-aa, aa, distance);
    float rim = 1.0 - smoothstep(0.6, 1.8, abs(distance));
    vec3 colour = mix(kFill, kAccent, rim * 0.55);
    float inkAlpha = outline * visibility;
    vec4 shaded = source * (1.0 - inkAlpha) + vec4(vec3(0.025) * inkAlpha, inkAlpha);
    float fillAlpha = fill * visibility;
    return shaded * (1.0 - fillAlpha) + vec4(colour * fillAlpha, fillAlpha);
}
