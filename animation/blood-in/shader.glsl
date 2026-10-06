// Swipe-reveals window from top to bottom, matches with border and bloodOut animation.
const vec3 COLOR_DEEP     = vec3(0.10, 0.0, 0.01);  
const vec3 COLOR_BRIGHT   = vec3(0.60, 0.02, 0.035); 
const vec3 GLOSS_COLOR    = vec3(0.35, 0.05, 0.06);  
const float BLOOD_OPACITY = 0.94;

float bf_hash(float n) {
    return fract(sin(n * 127.1 + 311.7) * 43758.5453);
}

vec4 animation(vec2 uv) {
    float progress = umbriel_direction > 0.0 ? umbriel_clamped_progress : 1.0 - umbriel_clamped_progress;
    vec4 src = umbriel_sample(uv);
    float aa = 1.5 / max(umbriel_scale * umbriel_size.y, 0.001);

    // Front sweeps from y = -0.30 (hidden) down to y = 1.35 (fully revealed)
    float base_front = mix(-0.30, 1.35, progress);


    float x_aspect = uv.x * (umbriel_size.x / max(umbriel_size.y, 1.0));
    float wave = sin(x_aspect * 12.0 + umbriel_time * 1.8) * 0.025
    + sin(x_aspect * 26.0 - umbriel_time * 1.2) * 0.012;

    float drip_accum = 0.0;
    for (int i = 0; i < 5; i++) {
        float fi = float(i);
        float seed = bf_hash(fi + 17.0);
        float center = seed;
        float dist_x = abs(uv.x - center);
        float width = 0.025 + seed * 0.035;
        float drip_len = (0.05 + seed * 0.12) * (0.6 + 0.4 * sin(umbriel_time * 2.2 + seed * 6.28));
        float profile = exp(-pow(dist_x / width, 2.0));

        drip_accum = max(drip_accum, profile * drip_len);
    }

    float leading_edge = base_front + wave + drip_accum;

    // Window reveal mask
    //float reveal = smoothstep(leading_edge + aa, leading_edge - aa, uv.y);
    float reveal = 1.0 - smoothstep(leading_edge - aa, leading_edge +aa, uv.y);
    if (reveal <= 0.0) {
        return vec4(0.0);
    }

    // Distance behind leading surface edge (y <= leading_edge)
    float dist_behind = max(leading_edge - uv.y, 0.0);
    float blood_band = 0.30;
    float surface_dist = clamp(dist_behind / blood_band, 0.0, 1.0);

    //float blood_intensity = smoothstep(1.0, 0.0, surface_dist) * reveal;
    float blood_intensity = (1.0 - smoothstep(0.0, 1.0, surface_dist)) * reveal;
    float gloss = exp(-pow(dist_behind * 35.0, 2.0)) * reveal * 0.22;

    float flecks = pow(0.5 + 0.5 * sin(uv.x * 40.0 + uv.y * 30.0 + umbriel_time * 2.0), 6.0);
    float clots = (drip_accum / 0.15) * 0.35 + flecks * 0.12;

    // Color gradient matching border
    vec3 blood_col = mix(COLOR_BRIGHT, COLOR_DEEP, surface_dist);
    blood_col -= vec3(0.06, 0.0, 0.0) * clots;
    blood_col += GLOSS_COLOR * gloss;

    vec3 src_unpremult = src.a > 0.001 ? src.rgb / src.a : vec3(0.0);
    vec3 blended = mix(src_unpremult, blood_col, blood_intensity * BLOOD_OPACITY);

    float final_alpha = src.a * reveal;
    return vec4(clamp(blended, 0.0, 1.0) * final_alpha, final_alpha);
}
