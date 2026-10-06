// Drains window away toward bottom with blood colors matching border and fill shaders.
const vec3 COLOR_DEEP     = vec3(0.10, 0.0, 0.01);   // Near-black clotted core
const vec3 COLOR_BRIGHT   = vec3(0.60, 0.02, 0.035); // Deep arterial crimson
const vec3 GLOSS_COLOR    = vec3(0.35, 0.05, 0.06);  // Wet specular sheen
const float BLOOD_OPACITY = 0.94;

vec4 animation(vec2 uv) {
    float progress = umbriel_direction > 0.0 ? umbriel_clamped_progress : 1.0 - umbriel_clamped_progress;
    vec4 src = umbriel_sample(uv);
    float aa = 1.5 / max(umbriel_scale * umbriel_size.y, 0.001);

    // Drain boundary sweeps down from y = -0.25 (fully visible) to y = 1.25 (fully drained)
    float base_drain = mix(1.25, -0.25, progress);

    // Funnel suction curve pulling toward bottom center
    float center_dist = abs(uv.x - 0.5);
    float funnel = pow(center_dist * 2.0, 2.0) * 0.12;

    // Ripple wave motion along moving drain line
    float x_aspect = uv.x * (umbriel_size.x / max(umbriel_size.y, 1.0));
    float wave = sin(x_aspect * 14.0 - umbriel_time * 2.5) * 0.02
    + sin(x_aspect * 28.0 + umbriel_time * 1.2) * 0.01;

    float drain_level = base_drain + funnel + wave;

    // Window cutoff mask
    float mask = smoothstep(drain_level - aa, drain_level + aa, uv.y);
    if (mask <= 0.0) {
        return vec4(0.0);
    }

    // Distance ahead of moving drain surface (y >= drain_level)
    float dist_ahead = max(uv.y - drain_level, 0.0);
    float blood_band = 0.30;
    float surface_dist = clamp(dist_ahead / blood_band, 0.0, 1.0);

    // Smooth intensity dropoff ahead of drain boundary
    float blood_intensity = smoothstep(1.0, 0.0, surface_dist) * mask;
    float gloss = exp(-pow(dist_ahead * 35.0, 2.0)) * mask * 0.22;

    // Color gradient matching border and fill shaders
    vec3 blood_col = mix(COLOR_BRIGHT, COLOR_DEEP, surface_dist);
    blood_col += GLOSS_COLOR * gloss;

    // Unpremultiply source and blend blood layer
    vec3 src_unpremult = src.a > 0.001 ? src.rgb / src.a : vec3(0.0);
    vec3 blended = mix(src_unpremult, blood_col, blood_intensity * BLOOD_OPACITY);

    float final_alpha = src.a * mask;
    return vec4(clamp(blended, 0.0, 1.0) * final_alpha, final_alpha);
}
