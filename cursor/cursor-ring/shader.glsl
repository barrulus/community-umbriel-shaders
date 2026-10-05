// Adapted from shaders/cursor/cursor-ring.glsl

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
vec4 postprocess(vec3 coords) {
  vec2 uv = coords.xy;
  vec4 under = tex2D_screen(uv);
  float d = length((uv * umbriel_output_size - umbriel_cursor) / max(umbriel_scale, 0.01));
  float pulse = sin(umbriel_time * 3.0);
  float radius = 42.0 + 8.0 * pulse;
  float aa = 1.0 / max(umbriel_scale, 0.01);
  float a = (1.0 - smoothstep(0.75, 0.75 + aa, abs(d - radius))) * (0.7 + 0.3 * pulse);
  vec3 color = theme_color(vec3(0.55, 0.85, 1.0), 0.25);
  return vec4(color * a, a) + under * (1.0 - a);
}

vec4 cursor(vec2 uv) { return postprocess(vec3(uv, 0.0)); }
