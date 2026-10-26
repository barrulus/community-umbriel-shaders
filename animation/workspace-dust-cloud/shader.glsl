// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Barrulus
// Adapted from the session workspace-pair shader to the full-scene reveal API.
uniform vec2 umbriel_workspace_axis;

float workspace_sign() {
    return umbriel_workspace_axis.x + umbriel_workspace_axis.y < 0.0 ? -1.0 : 1.0;
}

// Stationary images fracture into independently jittered rigid dust grains.
// Only particle centres move: neither workspace image is stretched or warped.
const float fragment_size = 9.0;
const float cloud_spread = 0.16;

float dust_hash(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * 0.1031);
    q += dot(q, q.yzx + 33.33 + umbriel_random_seed.x);
    return fract((q.x + q.y) * q.z);
}
vec2 dust_random(vec2 id) {
    return vec2(dust_hash(id), dust_hash(id + 71.37));
}
vec4 dust_source(vec2 uv, float destination) {
    if (destination > 0.5) return umbriel_sample_incoming(uv);
    return umbriel_sample(uv);
}

// Each layer transports rigid points, with independent positions, velocities,
// sizes and release times. A bounded neighbourhood finds displaced grains;
// sample only the winning grain, rather than taking nine texture reads.
vec4 dust_particles(vec2 uv, float travel, float destination, float layer) {
    float size = max(1.8, fragment_size * mix(0.30, 0.68, layer / 3.0));
    vec2 grid = max(umbriel_size / size, vec2(1.0));
    float angle = layer * 2.39996323 + umbriel_random_seed.y * 6.2831853;
    vec2 wind = vec2(cos(angle), sin(angle));
    wind.x *= workspace_sign() < 0.0 ? -1.0 : 1.0;
    // Outgoing grains keep travelling out. Incoming grains gather from their
    // dispersed positions; there is no screen-shaped bulge at the midpoint.
    vec2 drift = wind * cloud_spread * travel * (0.6 + 0.18 * layer);
    vec2 point = (uv - drift) * grid;
    vec2 base = floor(point);
    float coverage = 0.0;
    vec2 source_uv = vec2(0.0);
    float shade = 1.0;
    for (int y = -1; y <= 1; ++y) {
        for (int x = -1; x <= 1; ++x) {
            vec2 cell = base + vec2(float(x), float(y));
            vec2 id = cell + layer * 137.31;
            vec2 jitter = dust_random(id) - 0.5;
            vec2 velocity = dust_random(id + 39.6) - 0.5;
            vec2 center = cell + 0.5 + jitter * 0.50 + velocity * travel * 1.1;
            float random = dust_hash(id + 17.0);
            float radius = mix(0.10, 0.29, random);
            vec2 delta = point - center;
            // Irregular tiny rigid chips, not long continuous image strips.
            float spin = random * 6.2831853 + travel * (random - 0.5) * 4.0;
            vec2 rotated = mat2(cos(spin), -sin(spin), sin(spin), cos(spin)) * delta;
            float distance = max(abs(rotated.x), abs(rotated.y) * (0.7 + random));
            float aa = min(0.18, 0.65 / max(size * umbriel_scale, 1.0));
            float mask = 1.0 - smoothstep(radius - aa, radius + aa, distance);
            // Exchange grains at different times, while both clouds coexist.
            // Held cell randomness keeps this smooth when progress reverses.
            float p = umbriel_clamped_progress;
            float delay = random * 0.12;
            float lifetime = destination > 0.5
                ? smoothstep(0.10 + delay, 0.48 + delay, p)
                : 1.0 - smoothstep(0.40 + delay, 0.78 + delay, p);
            mask *= lifetime;
            if (mask > coverage) {
                coverage = mask;
                source_uv = (cell + 0.5 + jitter * 0.50) / grid;
                shade = 0.75 + random * 0.25;
            }
        }
    }
    vec4 color = dust_source(source_uv, destination);
    color.rgb *= shade;
    // Fine powder catches a little light, including grains from dark surfaces.
    color.rgb = mix(color.rgb, vec3(0.30, 0.27, 0.23) * color.a, 0.14);
    return color * coverage;
}

vec4 dust_cloud(vec2 uv, float travel, float destination) {
    vec4 cloud = vec4(0.0);
    for (int i = 0; i < 4; ++i) {
        vec4 grain = dust_particles(uv, travel, destination, float(i));
        cloud += grain * (1.0 - cloud.a);
    }
    return cloud;
}

vec4 dust_cracked_image(vec2 uv, float erosion, float destination) {
    vec2 grid = max(umbriel_size / max(fragment_size, 3.0), vec2(1.0));
    vec2 cell = floor(uv * grid);
    vec2 local = fract(uv * grid);
    float random = dust_hash(cell + destination * 47.0);
    float edge = min(min(local.x, 1.0 - local.x), min(local.y, 1.0 - local.y));
    float diagonal = abs(local.x - local.y + (random - 0.5) * 0.6) * 0.7071;
    float crack = min(edge, diagonal);
    float width = 0.12 * smoothstep(0.0, 0.35, erosion);
    float cracked = mix(1.0, smoothstep(width, width + 0.025, crack),
                        smoothstep(0.0, 0.15, erosion));
    float remaining = 1.0 - smoothstep(0.08 + random * 0.42, 0.45 + random * 0.50, erosion);
    // Sample the original, untransformed coordinate throughout fracture.
    return dust_source(uv, destination) * cracked * remaining;
}

vec4 animation(vec2 uv) {
    float p = umbriel_clamped_progress;
    if (p <= 0.0) return umbriel_sample(uv);
    if (p >= 1.0) return umbriel_sample_incoming(uv);

    float handoff = smoothstep(0.18, 0.82, p);
    float from_erosion = smoothstep(0.0, 0.28, p);
    float to_erosion = 1.0 - smoothstep(0.72, 1.0, p);
    // Hold a dust-only middle section long enough to read as a cloud.
    float dust_weight = smoothstep(0.02, 0.22, p) * (1.0 - smoothstep(0.78, 0.98, p));
    vec4 cloud;
    if (p <= 0.10) {
        cloud = dust_cloud(uv, p * 1.4, 0.0);
    } else if (p >= 0.90) {
        cloud = dust_cloud(uv, (1.0 - p) * 1.4, 1.0);
    } else {
        vec4 outgoing = dust_cloud(uv, p * 1.4, 0.0);
        vec4 incoming = dust_cloud(uv, (1.0 - p) * 1.4, 1.0);
        // Composite the overlapping clouds instead of replacing one with the
        // other. Ease their depth order too, without a single midpoint switch.
        cloud = mix(outgoing + incoming * (1.0 - outgoing.a),
                    incoming + outgoing * (1.0 - incoming.a), handoff);
    }
    cloud *= dust_weight;
    vec4 image = mix(dust_cracked_image(uv, from_erosion, 0.0),
                     dust_cracked_image(uv, to_erosion, 1.0), handoff);
    vec4 result = image + cloud * (1.0 - image.a);

    // Dark coverage obscures the intact live scene beneath the floating dust.
    vec4 backdrop = mix(umbriel_sample(vec2(0.5)), umbriel_sample_incoming(vec2(0.5)), handoff);
    backdrop.rgb *= 0.045;
    backdrop *= smoothstep(0.0, 0.12, p) * (1.0 - smoothstep(0.88, 1.0, p));
    return result + backdrop * (1.0 - result.a);
}
