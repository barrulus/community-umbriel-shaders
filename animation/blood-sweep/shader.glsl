uniform vec2 umbriel_workspace_axis;

const vec3 COLOR_DEEP     = vec3(0.10, 0.0, 0.01);
const vec3 COLOR_BRIGHT   = vec3(0.60, 0.02, 0.035);
const vec3 GLOSS_COLOR    = vec3(0.35, 0.05, 0.06);
const float BLOOD_OPACITY = 0.94;
const float BLOOD_BAND    = 0.30; // Trail length behind the front, as a fraction of the sweep axis.

float bs_hash(float n) {
    return fract(sin(n * 127.1 + 311.7) * 43758.5453);
}

vec4 animation(vec2 uv) {
    float p = umbriel_clamped_progress;
    if (p <= 0.0) return umbriel_sample(uv);
    if (p >= 1.0) return umbriel_sample_incoming(uv);

    // Down: blood travels top -> bottom. Up: bottom -> top.
    bool upwards = umbriel_workspace_axis.x + umbriel_workspace_axis.y < 0.0;
    float y = upwards ? 1.0 - uv.y : uv.y;
    float aa = 1.5 / max(umbriel_scale * umbriel_size.y, 0.001);

    // Front sweeps from y = -0.30 (hidden) to y = 1.35 (trail fully off-screen)
    float base_front = mix(-0.30, 1.35, p);

    // Ripple wave motion along the moving front
    float x_aspect = uv.x * (umbriel_size.x / max(umbriel_size.y, 1.0));
    float wave = sin(x_aspect * 12.0 + umbriel_time * 1.8) * 0.025
    + sin(x_aspect * 26.0 - umbriel_time * 1.2) * 0.012;

    // Gaussian drips hanging below the front
    float drip_accum = 0.0;
    for (int i = 0; i < 5; i++) {
        float fi = float(i);
        float seed = bs_hash(fi + 17.0);
        float dist_x = abs(uv.x - seed);
        float width = 0.025 + seed * 0.035;
        float drip_len = (0.05 + seed * 0.12) * (0.6 + 0.4 * sin(umbriel_time * 2.2 + seed * 6.28));
        float profile = exp(-pow(dist_x / width, 2.0));
        drip_accum = max(drip_accum, profile * drip_len);
    }

    float leading_edge = base_front + wave + drip_accum;

    // Behind the front: incoming scene. Ahead of it: outgoing scene.
    float reveal = 1.0 - smoothstep(leading_edge - aa, leading_edge + aa, y);
    // Blood covers the scene swap so the cut is never visible.
    float cover = 1.0 - smoothstep(leading_edge + aa, leading_edge + 2.5 * aa, y);

    float dist_behind = max(leading_edge - y, 0.0);
    float surface_dist = clamp(dist_behind / BLOOD_BAND, 0.0, 1.0);

    float blood_intensity = (1.0 - smoothstep(0.0, 1.0, surface_dist)) * cover;
    float gloss = exp(-pow(dist_behind * 35.0, 2.0)) * cover * 0.22;

    float flecks = pow(0.5 + 0.5 * sin(uv.x * 40.0 + y * 30.0 + umbriel_time * 2.0), 6.0);
    float clots = (drip_accum / 0.15) * 0.35 + flecks * 0.12;

    vec3 blood_col = mix(COLOR_BRIGHT, COLOR_DEEP, surface_dist);
    blood_col -= vec3(0.06, 0.0, 0.0) * clots;
    blood_col += GLOSS_COLOR * gloss;
    blood_col = clamp(blood_col, 0.0, 1.0);

    vec4 scene = mix(umbriel_sample(uv), umbriel_sample_incoming(uv), reveal);

    scene.rgb = mix(scene.rgb, blood_col * scene.a, blood_intensity * BLOOD_OPACITY);
    return scene;
}
