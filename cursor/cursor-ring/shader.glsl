// Adapted from shaders/cursor/cursor-ring.glsl
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
  vec3 color = vec3(0.55, 0.85, 1.0);
  return vec4(color * a, a) + under * (1.0 - a);
}

vec4 cursor(vec2 uv) { return postprocess(vec3(uv, 0.0)); }
