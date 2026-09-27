// Adapted from shaders/animations/water-splash.glsl
// A water-drop impact seen from above. Recommended windows_out duration: 850 ms.
// Uses the linear clock so the gather, impact and ripples keep their timing even
// with a spring curve. All water stays inside the original window's canvas.
const float SPLASH_TAU = 6.28318530718;

float splash_hash(float n) {
    return fract(sin(n * 127.1 + 31.7) * 43758.5453);
}

// Tint and highlights remain premultiplied, including translucent clients.
vec4 splash_water(vec2 uv, float light, float wetness) {
    vec4 color = umbriel_sample(uv);
    vec3 water = color.rgb * vec3(0.64, 0.88, 0.98)
        + vec3(0.035, 0.14, 0.19) * color.a;
    color.rgb = mix(color.rgb, water, wetness);
    color.rgb = mix(color.rgb, vec3(0.78, 0.94, 1.0) * color.a,
        clamp(light * wetness, 0.0, 0.85));
    return color;
}

vec4 animation(vec2 uv) {
    float t = clamp(umbriel_linear_progress, 0.0, 1.0);
    if (umbriel_direction > 0.0) t = 1.0 - t;
    if (t <= 0.0) return umbriel_sample(uv);
    if (t >= 1.0) return vec4(0.0);

    // Isotropic coordinates keep a circular splash on wide and tall windows.
    vec2 size = max(umbriel_size, vec2(1.0));
    float unit = min(size.x, size.y);
    vec2 aspect = size / unit;
    vec2 p = (uv - 0.5) * aspect;
    float r = length(p);
    vec2 radial = p / max(r, 0.0001);
    float angle = atan(p.y, p.x + 0.00001);
    float aa = 1.25 / unit;
    float seed = umbriel_random_seed.x * SPLASH_TAU;
    float gather = smoothstep(0.0, 0.34, t);
    float impact = smoothstep(0.29, 0.76, t);
    float fade = 1.0 - smoothstep(0.68, 1.0, t);

    // The rectangle rounds off and contracts into a glossy bead of its content.
    vec2 halfSize = mix(0.5 * aspect, vec2(0.105), gather);
    float rounding = min(halfSize.x, halfSize.y) * gather;
    vec2 box = abs(p) - halfSize + rounding;
    float bodyDistance = length(max(box, 0.0))
        + min(max(box.x, box.y), 0.0) - rounding;
    float bodyMask = (1.0 - smoothstep(-aa, aa, bodyDistance))
        * (1.0 - smoothstep(0.33, 0.52, t));
    vec2 bodyUV = p / (2.0 * halfSize) + 0.5;
    bodyUV += radial * sin(r * 42.0 - t * 18.0) * 0.022 * gather;
    float bodyRim = exp(-abs(bodyDistance) / max(aa, 0.009));
    float lighting = 0.35 + 0.65 * pow(max(dot(radial, vec2(-0.6, -0.8)), 0.0), 3.0);
    vec4 result = splash_water(bodyUV, bodyRim * lighting, gather) * bodyMask;

    // A scalloped crown spreads out from the impact; its centre opens into air.
    float lobes = sin(angle * 9.0 + seed) * 0.65
        + sin(angle * 13.0 - seed * 1.7) * 0.35;
    float crownRadius = mix(0.095, 0.335, impact);
    float crownWave = 0.022 * sin(impact * 3.14159265) * lobes;
    float crownWidth = mix(0.043, 0.005, impact);
    float crownDistance = abs(r - crownRadius - crownWave) - crownWidth;
    float crownMask = (1.0 - smoothstep(-aa, aa, crownDistance))
        * smoothstep(0.29, 0.39, t) * fade;
    float crownRim = exp(-abs(crownDistance) / max(aa, 0.004));
    vec2 crownUV = 0.5 + radial * (0.24 + 0.09 * sin(r * 95.0 - t * 22.0));
    vec4 crown = splash_water(crownUV, crownRim * lighting + 0.15, 1.0) * crownMask;
    result = crown + result * (1.0 - crown.a);

    // Detached beads fly radially, with a stable but different pattern per close.
    for (int i = 0; i < 12; ++i) {
        float n = float(i);
        float random = splash_hash(n + umbriel_random_seed.y * 19.0);
        float theta = SPLASH_TAU * (n + 0.23 * random) / 12.0 + seed;
        vec2 direction = vec2(cos(theta), sin(theta));
        float travel = smoothstep(0.35, 0.84, t);
        float distance = mix(0.12, 0.38 + 0.065 * random, travel);
        vec2 delta = p - direction * distance;
        // Elongation along the flight path relaxes back to a round droplet.
        vec2 bead = vec2(dot(delta, direction), dot(delta, vec2(-direction.y, direction.x)));
        bead.x /= mix(1.9, 1.0, travel);
        float radius = (0.013 + 0.014 * random) * (1.0 - 0.5 * travel);
        float beadDistance = length(bead) - radius;
        float mask = (1.0 - smoothstep(-aa, aa, beadDistance))
            * smoothstep(0.35, 0.44, t) * (1.0 - smoothstep(0.65, 0.94, t));
        float glint = 1.0 - smoothstep(0.0, radius,
            length(bead + radius * vec2(0.3, 0.35)));
        vec4 drop = splash_water(0.5 + direction * 0.3, 0.2 + 0.65 * glint, 1.0) * mask;
        result = drop + result * (1.0 - drop.a);
    }

    // Thin concentric waves follow the crown and quietly dissipate.
    for (int i = 0; i < 3; ++i) {
        float age = (t - 0.38 - float(i) * 0.095) / 0.62;
        float wave = clamp(age, 0.0, 1.0);
        float radius = mix(0.13, 0.455, wave);
        float width = mix(0.005, 0.0015, wave);
        float ring = 1.0 - smoothstep(width, width + aa, abs(r - radius));
        float opacity = ring * smoothstep(0.0, 0.09, wave)
            * (1.0 - smoothstep(0.25, 0.95, wave)) * fade * 0.48;
        vec4 ripple = splash_water(0.5 + radial * 0.32, lighting * 0.75, 1.0) * opacity;
        result = ripple + result * (1.0 - ripple.a);
    }
    return result;
}
