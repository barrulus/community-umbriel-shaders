// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Barrulus
vec4 overGlow(vec4 base, vec3 tint, float alpha) {
    alpha = clamp(alpha, 0.0, 1.0);
    return vec4(tint * alpha, alpha) + base * (1.0 - alpha);
}

const float PORTAL_RADIUS = 0.36;
const float PORTAL_BAND = 0.10;

vec4 animation(vec2 uv) {
    float t = clamp(umbriel_linear_progress, 0.0, 1.0);
    bool opening = umbriel_direction > 0.0;
    if (t <= 0.0) return opening ? vec4(0.0) : umbriel_sample(uv);
    if (t >= 1.0) return opening ? umbriel_sample(uv) : vec4(0.0);

    float visible = opening ? t : 1.0 - t;
    vec2 aspect = umbriel_size / max(min(umbriel_size.x, umbriel_size.y), 1.0);
    vec2 p = (uv - 0.5) * aspect;
    float r = length(p);
    float angle = r > 0.00001 ? atan(p.y, p.x) : 0.0;
    float life = smoothstep(0.0, 0.15, visible) * (1.0 - smoothstep(0.72, 1.0, visible));
    float radius = mix(0.015, PORTAL_RADIUS, smoothstep(0.0, 0.45, visible));
    float bandWidth = PORTAL_BAND * smoothstep(0.0, 0.25, visible) + 0.005;
    // Curved ribbons spiral into an opaque black core. Time always turns inward.
    float winding = angle * 5.0 + log(max(r / radius, 0.015)) * 12.0 + t * 19.0;
    float ribbons = pow(0.5 + 0.5 * sin(winding), 3.0);
    float turbulence = 0.5 + 0.5 * sin(angle * 9.0 - r * 41.0 + t * 11.0);
    float ring = exp(-pow((r - radius) / bandWidth, 2.0));
    float interior = smoothstep(radius * 0.12, radius * 0.75, r)
        * (1.0 - smoothstep(radius * 0.85, radius + bandWidth, r));
    float hole = (1.0 - smoothstep(radius, radius + bandWidth * 0.6, r)) * life;
    vec4 portal = vec4(vec3(0.0), hole);
    float haze = exp(-abs(r - radius) / (bandWidth * 1.5)) * 0.3;
    float glow = (ring * (0.55 + 0.45 * turbulence) + interior * ribbons * 0.85 + haze) * life;
    vec3 violet = mix(vec3(0.25, 0.025, 0.62), vec3(0.73, 0.45, 1.0), ring * ribbons);
    portal = overGlow(portal, violet, glow);
    float emerge = smoothstep(0.22, 1.0, visible);
    float scale = mix(0.025, 1.0, emerge);
    float twist = (1.0 - emerge) * 2.2;
    // The inner part of the captured window winds more strongly into the core.
    twist += (1.0 - emerge) * 1.15 * exp(-r / max(radius, 0.01));
    float c = cos(twist), s = sin(twist);
    vec2 source = (mat2(c, -s, s, c) * p) / (aspect * scale) + 0.5;
    vec4 window = umbriel_sample(source) * smoothstep(0.24, 0.48, visible);
    window.rgb = mix(window.a * vec3(0.32, 0.13, 0.6), window.rgb, emerge);
    return window + portal * (1.0 - window.a);
}
