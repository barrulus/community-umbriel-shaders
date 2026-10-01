// Adapted from shaders/window/adaptive-text-v4.glsl
vec4 tex2D_screen(vec2 uv) { return umbriel_sample(uv); }
vec2 migration_buffer_size() { return umbriel_size * umbriel_scale; }
#define umbriel_size migration_buffer_size()
// Custom shader by Barrulus.
// Descending smoothstep edges in the original are undefined in GLSL.
float smoothstep_any_order(float a, float b, float x) {
    return a > b ? 1.0 - smoothstep(b, a, x) : smoothstep(a, b, x);
}

const float RADIUS = 10.0;
const float GAIN   = 2.2;
const float KNEE0  = 0.08;
const float KNEE1  = 0.22;
const float DIM    = 0.65;
const float DIMLO  = 0.30;
const float DIMHI  = 0.65;

float lum(vec3 c){ return dot(c, vec3(0.299, 0.587, 0.114)); }

vec4 postprocess(vec3 c){
    vec4 s  = tex2D_screen(c.xy);
    vec2 px = 1.0 / max(umbriel_size, vec2(1.0));

    // Backdrop estimate: 17-tap two-ring blur (8 at RADIUS, 8 at RADIUS/2, plus center).
    vec3 m = s.rgb;
    for (int i = 0; i < 8; i++){
        float a = 0.7853982 * float(i);
        vec2  d = vec2(cos(a), sin(a)) * px;
        m += tex2D_screen(c.xy + d * RADIUS).rgb;
        m += tex2D_screen(c.xy + d * (RADIUS * 0.5)).rgb;
    }
    m /= 17.0;

    // Adaptive dim: bright backdrop pixels get pulled down, dark ones stay as they are.
    float dimf = mix(1.0, DIM, smoothstep_any_order(DIMLO, DIMHI, lum(m)));

    // Soft-knee detail gain: wallpaper-scale amplitudes pass at 1.0, glyph-scale amplified.
    vec3  detail = s.rgb - m;
    float amp    = max(abs(lum(detail)), length(detail) * 0.5);
    float g      = mix(1.0, GAIN, smoothstep_any_order(KNEE0, KNEE1, amp));

    vec3 outc = m * dimf + detail * g;
    return vec4(clamp(outc, 0.0, 1.0), s.a);
}

vec4 window(vec2 uv) { return postprocess(vec3(uv, 0.0)); }
