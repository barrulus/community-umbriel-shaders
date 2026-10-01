// Adapted from shaders/window/rgb-border.glsl
vec4 tex2D_screen(vec2 uv) { return umbriel_sample(uv); }
vec2 migration_buffer_size() { return umbriel_size * umbriel_scale; }
#define umbriel_size migration_buffer_size()
// Custom shader by Barrulus.
// Descending smoothstep edges are undefined in GLSL; preserve descending-edge falloff explicitly.
float smoothstep_any_order(float a, float b, float x) {
    return a > b ? 1.0 - smoothstep(b, a, x) : smoothstep(a, b, x);
}
vec4 postprocess(vec3 c){
        vec4 s = tex2D_screen(c.xy);

        // distance to the nearest window edge (0 at edge, grows inward)
        float edge = min(min(c.x, 1.0-c.x), min(c.y, 1.0-c.y));
        // soft inner bleed only — no crisp bright rim, so it doesn't sit over edge text
        float m    = clamp(smoothstep_any_order(0.070, 0.0, edge) * 0.99, 0.0, 1.0);

        // hue chases around the perimeter (angle) and cycles over time
        float ang = atan(c.y-0.5, c.x-0.5) * 0.1591549;      // /(2pi) -> -0.5..0.5
        float hue = fract(ang + umbriel_time*0.25);
        vec3  rgb = 0.5 + 0.5*cos(6.2831853*(hue + vec3(0.0,0.33,0.67)));  // IQ rainbow

        return vec4(s.rgb + rgb*m, s.a);                     // additive RGB glow
    }

vec4 window(vec2 uv) { return postprocess(vec3(uv, 0.0)); }
