// Adapted from shaders/window/rainbow-waves.glsl

// Theme colours affect artwork only; palette = false restores the original RGB.
// Keep the original shade and soften highlights without changing effect opacity.
vec3 theme_color(vec3 original, float position) {
    if (umbriel_palette_count <= 0) return original;
    float value = max(original.r, max(original.g, original.b));
    float white = min(original.r, min(original.g, original.b)) / max(value, 0.0001);
    return value * mix(umbriel_palette_at(position).rgb, vec3(1.0), white * 0.75);
}

vec4 tex2D_screen(vec2 uv) { return umbriel_sample(uv); }
vec2 migration_buffer_size() { return umbriel_size * umbriel_scale; }
#define umbriel_size migration_buffer_size()
// Custom shader by Barrulus.
// Descending smoothstep edges are undefined in GLSL; preserve descending-edge falloff explicitly.
float smoothstep_any_order(float a, float b, float x) {
    return a > b ? 1.0 - smoothstep(b, a, x) : smoothstep(a, b, x);
}

float hash(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

float vnoise(vec2 p){
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p){
    float v   = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 3; i++){
        v  += amp * vnoise(p);
        p   = p * 2.03 + vec2(1.7, 9.2);
        amp *= 0.5;
    }
    return v;
}

// IQ cosine rainbow: hue 0..1 -> full spectrum
vec3 rainbow(float h){ if (umbriel_palette_count > 0) return umbriel_palette_at(h).rgb; return 0.5 + 0.5 * cos(6.2831853 * (h + vec3(0.0, 0.33, 0.67))); }

vec4 postprocess(vec3 c){
    vec4  s  = tex2D_screen(c.xy);
    float ar = umbriel_size.x / max(umbriel_size.y, 1.0);
    float t  = umbriel_time;

    const float BANDS    = 1.6;
    const float SPEED    = 0.22;
    const float STRENGTH = 0.42;
    const float WOBBLE   = 0.10;
    const float WARP     = 0.12;
    const float TURN     = 0.06;
    const float CROSS    = 0.25;
    const float FOAM     = 0.25;
    const float SAT      = 0.90;

    vec2  a    = vec2(c.x * ar, c.y);
    float gate = smoothstep_any_order(0.0, 0.25, s.a);       // respect rounded corners

    // the travel direction swings slowly around a diagonal
    float th  = 0.45 + 0.6 * sin(t * TURN);
    vec2  dir = vec2(cos(th), sin(th));
    vec2  prp = vec2(-dir.y, dir.x);
    float u   = dot(a, dir);
    float v   = dot(a, prp);

    // undulate the fronts: a sinusoidal wobble plus a slow noise bend
    u += sin(v * 4.0 + t * 0.7) * WOBBLE;
    u += (fbm(a * 1.8 + vec2(t * 0.06, -t * 0.04)) - 0.5) * WARP * 2.0;

    // hue rides the wave phase, so a full spectrum sweeps by with each band
    float ph  = u * BANDS - t * SPEED;
    float hue = fract(ph);
    vec3  col = rainbow(hue);
    col = mix(vec3(dot(col, vec3(0.299, 0.587, 0.114))), col, SAT);

    // lit crest, shaded trough, faint foam line on the crest
    float crest = 0.5 + 0.5 * cos(6.2831853 * ph);
    col *= 0.80 + 0.30 * crest;
    col += theme_color(vec3(0.90, 0.95, 1.0), 0.25) * pow(crest, 12.0) * FOAM;

    // a second, fainter wave set crossing at an angle adds interference depth
    vec2  dir2 = vec2(cos(th + 1.9), sin(th + 1.9));
    float v2   = dot(a, vec2(-dir2.y, dir2.x));
    float u2   = dot(a, dir2) + sin(v2 * 3.0 - t * 0.5) * WOBBLE;
    vec3  col2 = rainbow(fract(u2 * BANDS * 0.7 + t * SPEED * 0.6));
    col = mix(col, col2, CROSS);

    // the swell surges and eases along the direction of travel
    float swell = 0.80 + 0.20 * sin(t * 0.5 + u * 2.0);
    float cov   = STRENGTH * swell * gate;

    // opaque element on a maybe-translucent window: push alpha with coverage
    return vec4(mix(s.rgb, col, cov), mix(s.a, 1.0, cov));
}

vec4 window(vec2 uv) { return postprocess(vec3(uv, 0.0)); }
