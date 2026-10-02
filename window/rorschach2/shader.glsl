// Adapted from shaders/window/rorschach2.glsl

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
// Descending smoothstep edges in the original are undefined in GLSL.
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

const float MORPH = 0.55;

// Domain-warped fbm, drifting slowly — warping the lookup by another moving fbm is what
// gives the blot its oozing, organic tendrils instead of round noise bubbles.
float blot(vec2 q){
    float t = umbriel_time * MORPH;
    vec2 w = vec2(fbm(q + vec2(0.0, t*0.11) + 3.7),
                  fbm(q + vec2(t*0.09, 0.0) + 1.3));
    return fbm(q + 2.2*w + vec2(0.0, t*0.03));
}

vec4 postprocess(vec3 c){
    vec4 s  = tex2D_screen(c.xy);
    vec2 ar = vec2(umbriel_size.x / max(umbriel_size.y, 1.0), 1.0);   // keep the blot round-ish

    const float OPACITY = 0.55;
    const float SPREAD  = 0.65;
    const float SCALE   = 3.0;
    const float WOBBLE  = 1.1;
    const float EDGE    = 0.012;

    // Centered, aspect-corrected coords; fold the card (mirror x) for bilateral symmetry.
    vec2  p = (c.xy - 0.5) * ar;
    vec2  q = vec2(abs(p.x), p.y) * SCALE;
    float r = length(p);

    // Deform the blot radius with the morphing field (plus a fine octave that roughens
    // the edge) and a slow breath, so it swells, splits into lobes and re-forms.
    float n      = (blot(q) - 0.47) + 0.10*(vnoise(q*9.0 + umbriel_time*0.2) - 0.5);
    float breath = 0.05*sin(umbriel_time*0.21);
    float radius = SPREAD * max(0.55 + breath + WOBBLE*n, 0.15);

    float ink = smoothstep_any_order(radius + EDGE, radius - EDGE, r);

    // Press near-black ink onto the content; everything outside the blot is untouched.
    vec3 black = theme_color(vec3(0.03, 0.03, 0.04), 0.25);
    return vec4(mix(s.rgb, black, ink * OPACITY), s.a);
}

vec4 window(vec2 uv) { return postprocess(vec3(uv, 0.0)); }
