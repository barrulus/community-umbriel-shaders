// Adapted from shaders/cursor/rainbow-tunnel.glsl

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
vec2 migration_pointer() { return umbriel_pointer * umbriel_size * umbriel_scale; }
#define umbriel_output_size migration_buffer_size()
#define umbriel_cursor migration_pointer()
#define umbriel_size migration_buffer_size()
// Shader by Barrulus, adapted for Umbriel.
// Descending smoothstep edges are undefined in GLSL.
float barrulus_smoothstep(float a, float b, float x) {
    return a > b ? 1.0 - smoothstep(b, a, x) : smoothstep(a, b, x);
}
vec4 postprocess(vec3 c){
        vec3 s  = tex2D_screen(c.xy).rgb;
        vec2 px = c.xy*umbriel_output_size;
        float d = length(px - umbriel_cursor);

        float t = d*0.07 + umbriel_time*1.0;
        vec3 tunnel = umbriel_palette_count > 0 ? umbriel_palette_at(t).rgb : 0.5 + 0.5*cos(6.2831853*(t + vec3(0.0,0.33,0.67)));
        float fill  = barrulus_smoothstep(54.0, 50.0, d);
        vec3 outc   = mix(s, tunnel, fill*0.09);

        float ring = barrulus_smoothstep(7.0,0.0,abs(d-55.0));
        float glow = barrulus_smoothstep(110.0,0.0,d)*0.3;
        float lum  = dot(s, vec3(0.299,0.587,0.114));
        vec3 ringCol = mix(theme_color(vec3(0.35,0.75,1.0), 0.25), theme_color(vec3(0.0,0.1,0.45), 0.25), barrulus_smoothstep(0.4,0.6,lum));
        float m = clamp(ring+glow,0.0,1.0);

        return vec4(mix(outc, ringCol, m*0.9), 1.0);
    }

vec4 cursor(vec2 uv) { return postprocess(vec3(uv, 0.0)); }
