// Adapted from shaders/rings/flowing-water.glsl by barrulus https://github.com/noctalia-dev/community-umbriel-shaders/tree/main/border/flowing-water
#define ring_padding 30.0
#define ring_size (umbriel_border_hole.zw * umbriel_size)
#define ring_width max((1.0 - umbriel_border_hole.w) * umbriel_size.y * 0.5 - ring_padding, 1.0)
#define ring_radius umbriel_border_radius
float ring_distance(vec2 coords) { return umbriel_border_distance(coords / umbriel_size + umbriel_border_hole.xy); }
const float BLOOD_SPEED = 0.35;
const float OOZE_HEIGHT = 6.0;
const float BLOOD_OPACITY = 0.94;
const float HEARTBEAT_HZ = 0.9;      // ~54 bpm

const float SWELL_REACH = 4.0;
const float DRIP_GLOW_REACH = 3.35;

float fb_perimeter(vec2 coords, vec2 size) {
    vec2 half_size = max(size * 0.5, vec2(1.0));
    vec2 inv_half = 1.0 / half_size;
    vec2 q = coords - half_size;
    float ax = abs(q.x) * inv_half.x;
    float ay = abs(q.y) * inv_half.y;
    q *= 1.0 / max(max(ax, ay), 0.0001);
    if (ay >= ax)
        return q.y < 0.0 ? q.x + half_size.x : size.x + size.y + half_size.x - q.x;
    return q.x > 0.0 ? size.x + q.y + half_size.y
    : 2.0 * size.x + size.y + half_size.y - q.y;
}

// Heartbeat
float fb_heartbeat(float t) {
    float phase = fract(t * HEARTBEAT_HZ);
    float a = phase * 9.0;
    float b = (phase - 0.18) * 14.0;
    return exp(-a * a) + 0.5 * exp(-b * b);
}

void blood_wave(float seed, float along, float d, float perimeter, float inv_perimeter, float t, float base, float height, float extent, float aa, float reach, inout float ooze, inout float swelling, inout float drips, inout float drip_glow) {
    float speed = 18.0 + seed * 22.0;          // slow crawl
    float x = seed * perimeter + t * speed;
    float head = x - perimeter * floor(x * inv_perimeter);
    float delta = along - head;
    delta -= perimeter * floor(delta * inv_perimeter + 0.5);
    float width = 30.0 + seed * 20.0;
    if (abs(delta) >= width * SWELL_REACH) return;

    float k = delta / width;
    float swell = exp(-k * k);
    ooze = max(ooze, swell * height);
    swelling = max(swelling, swell);

    float drip_delta = delta - (seed - 0.5) * 6.0;
    if (abs(drip_delta) >= reach) return;

    float cycle = fract(t * (0.18 + seed * 0.12) + seed * 3.0);
    float fall = cycle * cycle;                // accelerating fall
    float drip_d = base + height * 0.3 + fall * (extent - base) * 1.1;
    float taper = mix(2.2, 0.3, cycle);        // thin as it stretches
    float dist = length(vec2(drip_delta, (d - drip_d) * 0.4));
    float visible = smoothstep(0.0, 0.08, cycle) * (1.0 - smoothstep(0.85, 1.0, cycle));
    drips = max(drips, (1.0 - smoothstep(taper, taper + aa, dist)) * visible);
    float glow_raw = exp(-dist * 0.9);
    drip_glow = max(drip_glow, (glow_raw > 0.05 ? glow_raw : 0.0) * visible * 0.12);
}

    vec4 ring_color(vec2 coords) {
        float ring_w = ring_width;
        vec2 rs = ring_size;
        if (ring_w <= 0.0 || min(rs.x, rs.y) <= 0.0) return vec4(0.0);
        float d = ring_distance(coords);
        if (d <= 0.0) return vec4(0.0);
        float aa = 0.65 / max(umbriel_scale, 0.01);
        float pulse = fb_heartbeat(umbriel_time);
        float extent = min(ring_w + ring_padding, ring_w * 4.0 + 12.0) * (1.0 + pulse * 0.06);
        if (d >= extent) return vec4(0.0);
        float perimeter = 2.0 * (rs.x + rs.y);
        float inv_perimeter = 1.0 / perimeter;
        float along = fb_perimeter(coords, rs);
        float t = umbriel_time * BLOOD_SPEED;
        const float tau = 6.28318530718;

        float base = min(ring_w * 1.35, extent * 0.32) * (1.0 + pulse * 0.05);
        float height = min(OOZE_HEIGHT, extent * 0.30) * (0.85 + 0.15 * pulse);
        float reach = max(2.2 + aa, DRIP_GLOW_REACH);

        float ooze = 0.0;
        float swelling = 0.0;
        float drips = 0.0;
        float drip_glow = 0.0;

        blood_wave(0.06731168, along, d, perimeter, inv_perimeter, t, base, height, extent, aa, reach, ooze, swelling, drips, drip_glow);
        blood_wave(0.94521832, along, d, perimeter, inv_perimeter, t, base, height, extent, aa, reach, ooze, swelling, drips, drip_glow);
        blood_wave(0.19909202, along, d, perimeter, inv_perimeter, t, base, height, extent, aa, reach, ooze, swelling, drips, drip_glow);
        blood_wave(0.72817389, along, d, perimeter, inv_perimeter, t, base, height, extent, aa, reach, ooze, swelling, drips, drip_glow);
        blood_wave(0.10684148, along, d, perimeter, inv_perimeter, t, base, height, extent, aa, reach, ooze, swelling, drips, drip_glow);
        blood_wave(0.39348707, along, d, perimeter, inv_perimeter, t, base, height, extent, aa, reach, ooze, swelling, drips, drip_glow);

        float blood_alpha = 0.0;
        vec3 blood = vec3(0.0);
        float body_limit = base + max(1.5, height) + aa;
        if (d < body_limit) {
            float u = along * inv_perimeter;
            float fine_phase = u * max(floor(perimeter / 90.0), 1.0) * tau - t * 1.6;
            float broad_phase = u * max(floor(perimeter / 240.0), 1.0) * tau - t * 0.7;
            float surface = base + max(sin(fine_phase) * 0.6 + sin(broad_phase) * 0.9, ooze);
            float inner = 0.85 + 0.20 * sin(broad_phase + 1.2);
            float body = (1.0 - smoothstep(inner + aa, inner - aa, d)) * (1.0 - smoothstep(surface - aa, surface + aa, d));
            float depth = clamp((d - inner) / max(surface - inner, 1.0), 0.0, 1.0);

            float f = 0.5 + 0.5 * sin(fine_phase * 1.6 + d * 0.8);
            float f2 = f * f;
            float flecks = f2 * f2 * f2;                         // f^6
            float clots = swelling * 0.35 + flecks * 0.12;
            float gloss_band = 1.0 - smoothstep(0.9, 0.9 + aa, abs(d - (surface - 1.2)));
            float gloss = gloss_band * (0.20 + pulse * 0.15);

            const vec3 deep = vec3(0.10, 0.0, 0.01);             // near-black clotted core
            const vec3 bright = vec3(0.55, 0.02, 0.04);          // arterial crimson surface
            blood = mix(deep, bright, depth);
            blood -= vec3(0.06, 0.0, 0.0) * clots;               // darker clot flecks
            blood += vec3(0.35, 0.05, 0.06) * gloss;             // wet specular sheen
            blood_alpha = body * BLOOD_OPACITY * (0.85 + pulse * 0.10);
        }

        const vec3 drip_color = vec3(0.535, 0.03, 0.035);
        vec3 color_sum = blood * blood_alpha + drip_color * drips + vec3(0.5, 0.02, 0.03) * drip_glow;
        float total = blood_alpha + drips + drip_glow;
        float envelope = (1.0 - smoothstep(2.0 * aa, 0.0, d)) * (1.0 - smoothstep(max(extent - 2.0 * aa, 0.0), extent, d));
        return vec4(clamp(color_sum / max(total, 0.0001), 0.0, 1.0), clamp(total * envelope, 0.0, 1.0));
    }
    vec4 border(vec2 uv) {
       vec4 c = ring_color((uv - umbriel_border_hole.xy) * umbriel_size);
       return vec4(c.rgb * c.a, c.a);
    }
