// Adapted from shaders/window/snowfall.glsl

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
vec2 hash2(vec2 p){ return vec2(hash(p), hash(p + 19.19)); }

vec4 postprocess(vec3 c){
    vec4 s  = tex2D_screen(c.xy);
    vec2 ar = vec2(umbriel_size.x / max(umbriel_size.y, 1.0), 1.0);   // keep flakes round
    float snow = 0.0;

    for (int i = 0; i < 3; i++){
        float fi    = float(i);                    // 0 = nearest layer
        float scale = 14.0 + fi * 10.0;            // farther = finer flakes
        float speed = 0.055 - fi * 0.015;          // farther = slower fall

        vec2 p = c.xy * ar;
        p.x += sin(umbriel_time * 0.35 + fi * 2.1 + c.y * 4.0) * 0.012;   // gentle sway
        p.y -= umbriel_time * speed;                  // field scrolls -> flakes fall

        vec2  g    = p * scale;
        vec2  cell = floor(g);
        vec2  f    = fract(g);
        float on   = step(0.72, hash(cell + fi * 17.0));   // sparse: ~28% of cells
        vec2  fp   = 0.2 + 0.6 * hash2(cell + fi * 31.0);  // flake spot within its cell
        float d    = length(f - fp);
        float r    = 0.10 + 0.12 * hash(cell + 3.7);       // per-flake size
        float flake = smoothstep_any_order(r, r * 0.15, d);          // soft fuzzy disc

        snow += flake * on * (1.0 - fi * 0.3);             // nearer = brighter
    }

    const float OPACITY = 0.35;
    float m = min(snow, 1.0) * OPACITY * s.a;              // s.a: keep rounded corners clean
    return vec4(mix(s.rgb, theme_color(vec3(0.95, 0.97, 1.0), 0.25), m), s.a);
}

vec4 window(vec2 uv) { return postprocess(vec3(uv, 0.0)); }
