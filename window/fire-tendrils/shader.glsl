// Adapted from shaders/window/fire-tendrils.glsl

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
    vec2 i = floor(p), f = fract(p);
    f = f*f*(3.0 - 2.0*f);
    float a = hash(i), b = hash(i + vec2(1.0,0.0));
    float d = hash(i + vec2(0.0,1.0)), e = hash(i + vec2(1.0,1.0));
    return mix(mix(a,b,f.x), mix(d,e,f.x), f.y);
}

float fbm(vec2 p){
    float v = 0.0, a = 0.5;
    for (int i = 0; i < 4; i++){ v += a*vnoise(p); p *= 2.0; a *= 0.5; }
    return v;
}

// White-hot -> orange -> deep red as `temp` falls from 1 to 0.
vec3 heat_color(float temp){
    vec3 col = mix(theme_color(vec3(0.62, 0.05, 0.01), 0.75), theme_color(vec3(1.0, 0.34, 0.02), 0.5), smoothstep_any_order(0.02, 0.40, temp));
    col      = mix(col, theme_color(vec3(1.0, 0.74, 0.12), 0.5), smoothstep_any_order(0.38, 0.70, temp));
    return     mix(col, theme_color(vec3(1.0, 0.94, 0.72), 0.5), smoothstep_any_order(0.78, 1.00, temp));
}

vec4 postprocess(vec3 c){
    vec4  s  = tex2D_screen(c.xy);
    float ar = umbriel_size.x / max(umbriel_size.y, 1.0);
    float t  = umbriel_time;

    const float FLAME_HEIGHT = 0.40;
    const float THRESH       = 0.40;
    const float SLOPE        = 0.36;
    const float WARP         = 2.0;
    const float EDGE         = 0.022;
    const float XFREQ        = 10.0;
    const float YFREQ        = 3.4;
    const float RISE         = 1.6;
    const float BREAK        = 0.17;
    const float OPACITY      = 0.85;
    const float GLOW         = 0.35;

    float h = 1.0 - c.y;                                   // 0 at the bottom edge, 1 at the top
    if (h > FLAME_HEIGHT * 2.0) return s;                  // nothing burns up here

    float x  = c.x * ar;
    float hn = h / FLAME_HEIGHT;

    // The field, rising. Warping the lookup by two more drifting fBms is what grows tendrils
    // that can neck down and separate, instead of blobs that only fade.
    vec2  q = vec2(x * XFREQ, h * YFREQ - t * RISE);
    vec2  w = vec2(fbm(q * 0.6 + vec2(0.0, -t * 0.60) + 3.7),
                   fbm(q * 0.6 + vec2(t * 0.24, -t * 0.45) + 1.3));
    float n = fbm(q + WARP * w);
    n += BREAK * (vnoise(q * 3.5 + vec2(0.0, -t * 2.4)) - 0.5);   // fray the tips
    n *= 0.95 + 0.05 * sin(t * 9.0 + x * 5.0);                    // flicker

    // Threshold climbs with height: solid sheet -> tongues -> the tips pinch off -> nothing.
    float thr = THRESH + pow(max(hn, 0.0), 0.75) * SLOPE
              - smoothstep_any_order(0.05, 0.0, h) * 0.12;                  // anchor the base
    float fire = smoothstep_any_order(thr - EDGE, thr + EDGE, n);
    float halo = smoothstep_any_order(thr - 0.16, thr + 0.02, n);

    if (fire + halo <= 0.0) return s;

    // Temperature is anchored to HEIGHT, with the field only modulating it. Deriving it from
    // (n - thr) alone collapses toward 0 wherever the threshold ramp is shallow -- which is
    // exactly what raising FLAME_HEIGHT does -- and heat_color(0) is an opaque dark red, so the
    // window fills with brown mud instead of flames. Keep the height term dominant.
    float d    = clamp((n - thr) / 0.22, 0.0, 1.0);          // how deep inside the flame we are
    float temp = (0.55 + 0.45 * d) * (1.0 - smoothstep_any_order(0.0, 1.25, hn) * 0.85);

    // Composite the fire as its OWN layer (premultiplied "over"), so it reads on translucent
    // windows instead of merely tinting them; mask keeps it inside the rounded corners.
    float mask = smoothstep_any_order(0.0, 0.25, s.a);
    vec3  rgb  = s.rgb + theme_color(vec3(1.0, 0.42, 0.08), 0.5) * halo * GLOW * mask;
    float cov  = clamp(fire * OPACITY, 0.0, 1.0) * mask;
    rgb = mix(rgb, heat_color(temp), cov);
    return vec4(rgb, mix(s.a, 1.0, cov));
}

vec4 window(vec2 uv) { return postprocess(vec3(uv, 0.0)); }
