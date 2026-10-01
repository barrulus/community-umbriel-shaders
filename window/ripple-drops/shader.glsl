// Adapted from shaders/window/ripple-drops.glsl
vec4 tex2D_screen(vec2 uv) { return umbriel_sample(uv); }
vec2 migration_buffer_size() { return umbriel_size * umbriel_scale; }
#define umbriel_size migration_buffer_size()
// Custom shader by Barrulus.
// Descending smoothstep edges in the original are undefined in GLSL.
float smoothstep_any_order(float a, float b, float x) {
    return a > b ? 1.0 - smoothstep(b, a, x) : smoothstep(a, b, x);
}

float hash11(float n){ return fract(sin(n*127.1)      * 43758.5453); }
vec2  hash21(float n){ return fract(sin(vec2(n*127.1, n*311.7)) * 43758.5453); }

vec4 postprocess(vec3 c){
    vec2 uv = c.xy;
    vec2 ar = vec2(umbriel_size.x / max(umbriel_size.y, 1.0), 1.0);   // aspect correction -> round ripples

    const int   N    = 3;
    const float DUTY = 0.5;
    vec2  disp = vec2(0.0);
    float hi   = 0.0;

    for (int i = 0; i < N; i++) {
        float fi     = float(i);
        float period = 3.0 + hash11(fi + 0.3) * 3.5;
        float t      = umbriel_time / period + hash11(fi + 5.7) * 7.0;
        float life   = fract(t);                                // 0..1 within the slot's period
        vec2  origin = hash21(floor(t)*3.19 + fi*11.0);         // new random spot each cycle

        float p    = life / DUTY;                               // 0..1 while active, >1 while idle
        vec2  delta = uv - origin;
        float d    = length(delta * ar);                        // round distance to the drop
        float r    = p * 0.55;                                  // wavefront expands outward
        float env  = smoothstep_any_order(0.0, 0.08, p) * smoothstep_any_order(1.0, 0.5, p);  // fade in, out, and ZERO when idle (p>1)
        float wave = sin((d - r)*90.0) * exp(-abs(d - r)*22.0) * env;      // wavelets at the front

        vec2 dir = delta / max(length(delta), 1e-4);            // radial direction (uv space)
        disp += dir * wave * 0.010;                             // refract the content
        hi   += max(wave, 0.0);                                 // crest highlight
    }

    vec4 s = tex2D_screen(uv + disp);
    return vec4(s.rgb + hi*0.12, s.a);                          // content + subtle bright crests
}

vec4 window(vec2 uv) { return postprocess(vec3(uv, 0.0)); }
