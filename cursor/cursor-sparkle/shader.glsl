// Adapted from shaders/cursor/cursor-sparkle.glsl
vec4 tex2D_screen(vec2 uv) { return umbriel_sample(uv); }
vec2 migration_buffer_size() { return umbriel_size * umbriel_scale; }
vec2 migration_pointer() { return umbriel_pointer * umbriel_size * umbriel_scale; }
#define umbriel_output_size migration_buffer_size()
#define umbriel_cursor migration_pointer()
#define umbriel_size migration_buffer_size()
// Five palette-tinted dots orbiting the pointer at a wavering distance.
vec4 postprocess(vec3 coords) {
  vec2 uv = coords.xy;
  vec4 under = tex2D_screen(uv);
  vec2 p = (uv * umbriel_output_size - umbriel_cursor) / max(umbriel_scale, 0.01);
  float aa = 1.0 / max(umbriel_scale, 0.01);
  vec4 paint = vec4(0.0);
  for (int i = 0; i < 5; i++) {
    float k = float(i) / 5.0;
    float angle = umbriel_time * 1.6 + k * 6.2831853;
    float orbit = 50.0 + 12.0 * sin(umbriel_time * 2.3 + k * 11.0);
    float d = length(p - orbit * vec2(cos(angle), sin(angle)));
    float a = clamp(1.0 - smoothstep(2.5, 2.5 + aa, d) + 0.4 * exp(-d * 0.3), 0.0, 1.0);
    vec3 tint = umbriel_palette_count > 0 ? umbriel_palette_at(k).rgb : vec3(1.0, 0.9, 0.6);
    paint = vec4(tint * a, a) + paint * (1.0 - a);
  }
  return paint + under * (1.0 - paint.a);
}

vec4 cursor(vec2 uv) { return postprocess(vec3(uv, 0.0)); }
