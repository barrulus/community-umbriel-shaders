// Adapted from shaders/rings/pulse.glsl
#define ring_padding 0.0
#define ring_size (umbriel_border_hole.zw * umbriel_size)
#define ring_width max((1.0 - umbriel_border_hole.w) * umbriel_size.y * 0.5 - ring_padding, 1.0)
#define ring_radius umbriel_border_radius
float ring_distance(vec2 coords) { return umbriel_border_distance(coords / umbriel_size + umbriel_border_hole.xy); }
// Custom shader by Barrulus.
// A second, independent ring shader: cyan pigment gently brightens and fades.
// No deformation, so it needs no extra padding. Coordinates use logical pixels.
vec4 ring_color(vec2 coords) {
    float d = ring_distance(coords);
    float half_px = 0.5 / umbriel_scale;
    float coverage = smoothstep(-half_px, half_px, d)
        * (1.0 - smoothstep(ring_width - half_px, ring_width + half_px, d));
    float pulse = 0.65 + 0.35 * sin(umbriel_time * 2.0);
    return vec4(vec3(0.15, 0.8, 1.0) * pulse, coverage);
}

vec4 border(vec2 uv) {
    vec4 c = ring_color((uv - umbriel_border_hole.xy) * umbriel_size);
    return vec4(c.rgb * c.a, c.a);
}
