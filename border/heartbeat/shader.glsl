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

float fb_hash(float n) { return fract(sin(n * 127.1 + 311.7) * 43758.5453); }

float fb_perimeter(vec2 coords) {
    vec2 half_size = max(ring_size * 0.5, vec2(1.0));
    vec2 q = coords - half_size;
    q /= max(max(abs(q.x) / half_size.x, abs(q.y) / half_size.y), 0.0001);
    if (abs(q.y) / half_size.y >= abs(q.x) / half_size.x)
        return q.y < 0.0 ? q.x + half_size.x : ring_size.x + ring_size.y + half_size.x - q.x;
    return q.x > 0.0 ? ring_size.x + q.y + half_size.y
        : 2.0 * ring_size.x + ring_size.y + half_size.y - q.y;
}

// Heartbeat
float fb_heartbeat(float t) {
    float phase = fract(t * HEARTBEAT_HZ);
    float thump = exp(-pow(phase * 9.0, 2.0)) + 0.5 * exp(-pow((phase - 0.18) * 14.0, 2.0));
    return thump;
}

vec4 ring_color(vec2 coords) {
    if (ring_width <= 0.0 || min(ring_size.x, ring_size.y) <= 0.0) return vec4(0.0);
    float d = ring_distance(coords);
    float aa = 0.65 / max(umbriel_scale, 0.01);
    float pulse = fb_heartbeat(umbriel_time);
    float extent = min(ring_width + ring_padding, ring_width * 4.0 + 12.0) * (1.0 + pulse * 0.06);
    if (d <= 0.0 || d >= extent) return vec4(0.0);
    float perimeter = 2.0 * (ring_size.x + ring_size.y);
    float along = fb_perimeter(coords);
    float u = along / perimeter;
    float t = umbriel_time * BLOOD_SPEED;
    const float tau = 6.28318530718;

    float fine_phase = u * max(floor(perimeter / 90.0), 1.0) * tau - t * 1.6;
    float broad_phase = u * max(floor(perimeter / 240.0), 1.0) * tau - t * 0.7;
    float base = min(ring_width * 1.35, extent * 0.32) * (1.0 + pulse * 0.05);
    float surface = base + sin(fine_phase) * 0.6 + sin(broad_phase) * 0.9;
    float swelling = 0.0;
    float clots = 0.0;
    float drips = 0.0;
    float drip_glow = 0.0;
    
    for (int wave = 0; wave < 6; wave++) {
        float index = float(wave);
        float seed = fb_hash(index + 17.0);
        float speed = 18.0 + seed * 22.0; // slow crawl
        float head = mod(seed * perimeter + t * speed, perimeter);
        float delta = mod(along - head + perimeter * 0.5, perimeter) - perimeter * 0.5;
        float width = 30.0 + seed * 20.0;
        float swell = exp(-pow(delta / width, 2.0));
        float height = min(OOZE_HEIGHT, extent * 0.30) * (0.85 + 0.15 * pulse);
        float profile = swell * height;
        surface = max(surface, base + profile);
        swelling = max(swelling, swell);

        float cycle = fract(t * (0.18 + seed * 0.12) + seed * 3.0);
        float fall = cycle * cycle; // accelerating fall
        float drip_d = base + height * 0.3 + fall * (extent - base) * 1.1;
        float drip_delta = delta - (seed - 0.5) * 6.0;
        float taper = mix(2.2, 0.3, cycle); // thin as it stretches
        vec2 q = vec2(drip_delta, d - drip_d);
        float dist = length(q * vec2(1.0, 0.4));
        float visible = smoothstep(0.0, 0.08, cycle) * (1.0 - smoothstep(0.85, 1.0, cycle));
        drips = max(drips, (1.0 - smoothstep(taper, taper + aa, dist)) * visible);
        //drip_glow = max(drip_glow, exp(-dist * 0.9) * visible * 0.12);
        float glow_raw = exp(-dist * 0.9);
        drip_glow = max(drip_glow, (glow_raw > 0.05 ? glow_raw : 0.0) * visible * 0.12);        
    }

    float inner = 0.85 + 0.20 * sin(broad_phase + 1.2);
    float body = smoothstep(inner - aa, inner + aa, d)
        * (1.0 - smoothstep(surface - aa, surface + aa, d));
    float depth = clamp((d - inner) / max(surface - inner, 1.0), 0.0, 1.0);

    float fleck_phase = fine_phase * 1.6 + d * 0.8;
    float flecks = pow(0.5 + 0.5 * sin(fleck_phase), 6.0);
    clots = swelling * 0.35 + flecks * 0.12;
    float gloss_band = 1.0 - smoothstep(0.9, 0.9 + aa, abs(d - (surface - 1.2)));
    float gloss = gloss_band * (0.20 + pulse * 0.15);

    vec3 deep = vec3(0.10, 0.0, 0.01);          // near-black clotted core
    vec3 bright = vec3(0.55, 0.02, 0.04);        // arterial crimson surface
    vec3 blood = mix(deep, bright, depth);
    blood -= vec3(0.06, 0.0, 0.0) * clots;       // darker clot flecks
    blood += vec3(0.35, 0.05, 0.06) * gloss;     // wet specular sheen
    float blood_alpha = body * BLOOD_OPACITY * (0.85 + pulse * 0.10);
    vec3 drip_color = mix(vec3(0.42, 0.01, 0.02), vec3(0.65, 0.05, 0.05), 0.5);
    vec3 color_sum = blood * blood_alpha + drip_color * drips + vec3(0.5, 0.02, 0.03) * drip_glow;
    float total = blood_alpha + drips + drip_glow;
    float envelope = smoothstep(0.0, 2.0 * aa, d)
        * (1.0 - smoothstep(max(extent - 2.0 * aa, 0.0), extent, d));
    return vec4(clamp(color_sum / max(total, 0.0001), 0.0, 1.0), clamp(total * envelope, 0.0, 1.0));
}

vec4 border(vec2 uv) {
    vec4 c = ring_color((uv - umbriel_border_hole.xy) * umbriel_size);
    return vec4(c.rgb * c.a, c.a);
}
