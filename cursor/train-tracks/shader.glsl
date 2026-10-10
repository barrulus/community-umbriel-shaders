// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Barrulus
// Time-aware curve interpolation adapted from Comet / Noctalia's trail path.
const float TRACK_LIFE = 0.45;
const float MAX_TRACK_LENGTH = 150.0;
const float HALF_GAUGE = 8.0;
const float SLEEPER_SPACING = 14.0;
const float SLEEPER_HALF_LENGTH = 12.0;
const float OPACITY = 0.95;

vec2 trackPoint(vec2 a, vec2 b, vec2 m0, vec2 m1, float t) {
    float t2 = t * t;
    float t3 = t2 * t;
    return (2.0*t3 - 3.0*t2 + 1.0)*a + (t3 - 2.0*t2 + t)*m0
        + (3.0*t2 - 2.0*t3)*b + (t3 - t2)*m1;
}

vec2 trackNormal(vec2 a, vec2 b, vec2 m0, vec2 m1, float t) {
    vec2 tangent = (6.0*t*t - 6.0*t)*a + (3.0*t*t - 4.0*t + 1.0)*m0
        + (6.0*t - 6.0*t*t)*b + (3.0*t*t - 2.0*t)*m1;
    if (length(tangent) < 0.001) tangent = b - a;
    tangent /= max(length(tangent), 0.001);
    return vec2(-tangent.y, tangent.x);
}

float trackDistance(vec2 p, vec2 a, vec2 b) {
    vec2 edge = b - a;
    float t = clamp(dot(p - a, edge) / max(dot(edge, edge), 0.0001), 0.0, 1.0);
    return length(p - a - t*edge);
}

void trackSegment(vec2 here, vec4 p0, vec4 p1, vec4 p2, vec4 p3,
                  inout float distanceBehind, inout vec4 coverage) {
    vec2 a = p1.xy * umbriel_size;
    vec2 b = p2.xy * umbriel_size;
    vec2 chord = b - a;
    float chordLength = length(chord);
    // Ignore stationary samples and pointer warps, including their tangents.
    if (chordLength > 800.0 || p2.z >= TRACK_LIFE) {
        distanceBehind = MAX_TRACK_LENGTH;
        return;
    }
    if (chordLength < 0.25) return;
    if (length((p0.xy - p1.xy)*umbriel_size) > 800.0) p0 = p1;
    if (length((p3.xy - p2.xy)*umbriel_size) > 800.0) p3 = p2;
    float dt = max(p1.z - p2.z, 0.001);
    vec2 m0 = (b - p0.xy*umbriel_size)*dt / max(p0.z - p2.z, 0.001);
    vec2 m1 = (p3.xy*umbriel_size - a)*dt / max(p1.z - p3.z, 0.001);
    m0 *= min(1.0, 1.5*chordLength / max(length(m0), 0.001));
    m1 *= min(1.0, 1.5*chordLength / max(length(m1), 0.001));
    float bulge = (4.0/27.0)*(length(m0 - chord) + length(m1 - chord));

    // Space sleepers within each retained segment. No moving global phase:
    // removing old history must not make the entire railway slide backwards.
    float arcLength = 0.0;
    vec2 previous = a;
    for (int j = 1; j <= 6; ++j) {
        vec2 point = trackPoint(a, b, m0, m1, float(j)/6.0);
        arcLength += length(point - previous);
        previous = point;
    }
    // Account for every segment before pixel rejection so length is identical
    // across the image. Walk newest to oldest and fade the final 40% of track.
    float segmentStart = distanceBehind;
    distanceBehind += arcLength;
    if (trackDistance(here, a, b) > bulge + SLEEPER_HALF_LENGTH + 4.0) return;
    float tieCount = max(1.0, floor(arcLength / SLEEPER_SPACING + 0.5));
    float spacing = arcLength / tieCount;
    float travelled = 0.0;
    previous = a;
    vec2 previousNormal = trackNormal(a, b, m0, m1, 0.0);
    float aa = 0.75 / max(umbriel_scale, 0.5);
    for (int j = 1; j <= 6; ++j) {
        float t = float(j)/6.0;
        vec2 point = trackPoint(a, b, m0, m1, t);
        vec2 normal = trackNormal(a, b, m0, m1, t);
        vec2 edge = point - previous;
        float edgeLength = length(edge);
        float u = clamp(dot(here - previous, edge) / max(dot(edge, edge), 0.0001), 0.0, 1.0);
        float age = mix(p1.z, p2.z, (float(j) - 1.0 + u)/6.0);
        float behind = segmentStart + arcLength - (travelled + u*edgeLength);
        float fade = (1.0 - smoothstep(TRACK_LIFE*0.1, TRACK_LIFE, age))
            * (1.0 - smoothstep(MAX_TRACK_LENGTH*0.6, MAX_TRACK_LENGTH, behind));

        // Offset the actual curve on both sides; avoid ring-shaped segment caps.
        float rail = min(
            trackDistance(here, previous + HALF_GAUGE*previousNormal, point + HALF_GAUGE*normal),
            trackDistance(here, previous - HALF_GAUGE*previousNormal, point - HALF_GAUGE*normal));
        vec4 ink = vec4(0.0);
        ink.z = 1.0 - smoothstep(2.0 - aa, 2.0 + aa, rail);
        ink.w = 1.0 - smoothstep(0.85 - aa, 0.85 + aa, rail);

        // Local tangent coordinates give the sleepers square ends, not beads.
        vec2 tangent = edge / max(edgeLength, 0.0001);
        vec2 rel = here - previous;
        float along = dot(rel, tangent);
        float across = abs(dot(rel, vec2(-tangent.y, tangent.x)));
        if (along >= 0.0 && along <= edgeLength) {
            float tie = abs(mod(travelled + along, spacing) - 0.5*spacing);
            float halfWidth = min(2.5, spacing*0.24);
            float box = max(tie - halfWidth, across - SLEEPER_HALF_LENGTH);
            float inset = max(tie - max(halfWidth - 0.9, 0.1), across - (SLEEPER_HALF_LENGTH - 1.0));
            ink.x = 1.0 - smoothstep(-aa, aa, box);
            ink.y = 1.0 - smoothstep(-aa, aa, inset);
        }
        coverage = max(coverage, ink*fade);
        travelled += edgeLength;
        previous = point;
        previousNormal = normal;
    }
}

vec4 cursor(vec2 uv) {
    vec4 background = umbriel_sample(uv);
    vec4 coverage = vec4(0.0);
    vec4 p0 = vec4(0.0);
    vec4 p1 = p0;
    vec4 p2 = p0;
    vec4 p3 = p0;
    float distanceBehind = 0.0;
    for (int k = 63; k >= 0; --k) {
        if (distanceBehind >= MAX_TRACK_LENGTH) break;
        if (k < umbriel_pointer_count) {
            vec4 next = umbriel_pointer_path[k];
            if (k == umbriel_pointer_count - 1) { p0 = next; p1 = next; p2 = next; }
            p3 = p2; p2 = p1; p1 = p0; p0 = next;
            if (k < umbriel_pointer_count - 2)
                trackSegment(uv*umbriel_size, p0, p1, p2, p3, distanceBehind, coverage);
        }
    }
    if (umbriel_pointer_count >= 2 && distanceBehind < MAX_TRACK_LENGTH)
        trackSegment(uv*umbriel_size, p0, p0, p1, p2, distanceBehind, coverage);
    coverage *= OPACITY * smoothstep(3.0, 12.0, length((uv - umbriel_pointer)*umbriel_size));
    vec3 result = background.rgb;
    result = mix(result, vec3(0.16, 0.085, 0.035)*background.a, coverage.x);
    result = mix(result, vec3(0.52, 0.30, 0.13)*background.a, coverage.y);
    result = mix(result, vec3(0.12, 0.16, 0.20)*background.a, coverage.z);
    result = mix(result, vec3(0.80, 0.87, 0.91)*background.a, coverage.w);
    return vec4(result, background.a);
}
