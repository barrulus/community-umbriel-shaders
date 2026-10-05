// Adapted from shaders/cursor/seeing-stars.glsl

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
vec4 dizzy_over(vec4 under, vec4 paint) {
    return paint + under * (1.0 - paint.a);
}

vec2 dizzy_rotate(vec2 p, float angle) {
    float c = cos(angle), s = sin(angle);
    return vec2(c * p.x + s * p.y, -s * p.x + c * p.y);
}

float dizzy_oval(vec2 p, vec2 radius) {
    return (length(p / radius) - 1.0) * min(radius.x, radius.y);
}

float dizzy_segment(vec2 p, vec2 a, vec2 b) {
    vec2 edge = b - a;
    return length(p - a - edge * clamp(dot(p - a, edge) / dot(edge, edge), 0.0, 1.0));
}

float dizzy_cross(vec2 a, vec2 b) {
    return a.x * b.y - a.y * b.x;
}

float dizzy_triangle(vec2 p, vec2 a, vec2 b, vec2 c) {
    float distance = min(dizzy_segment(p, a, b), min(dizzy_segment(p, b, c), dizzy_segment(p, c, a)));
    float x = dizzy_cross(b - a, p - a);
    float y = dizzy_cross(c - b, p - b);
    float z = dizzy_cross(a - c, p - c);
    bool inside = (x >= 0.0 && y >= 0.0 && z >= 0.0) || (x <= 0.0 && y <= 0.0 && z <= 0.0);
    return inside ? -distance : distance;
}

vec4 dizzy_fill(float distance, vec3 color) {
    float aa = 0.65 / max(umbriel_scale, 0.01);
    float alpha = 1.0 - smoothstep(-aa, aa, distance);
    return vec4(color * alpha, alpha);
}

vec4 dizzy_ink(float distance, vec3 color) {
    vec4 edge = dizzy_fill(distance - 0.65, theme_color(vec3(0.16, 0.09, 0.045), 0.5));
    return dizzy_over(edge, dizzy_fill(distance + 0.10, color));
}

float dizzy_star(vec2 p, float radius) {
    float nearest = 100.0;
    bool inside = false;
    vec2 previous = vec2(0.0, -radius);
    for (int i = 1; i <= 10; i++) {
        float angle = -1.5707963 + float(i) * 0.62831853;
        float r = mod(float(i), 2.0) < 0.5 ? radius : radius * 0.44;
        vec2 current = r * vec2(cos(angle), sin(angle));
        nearest = min(nearest, dizzy_segment(p, previous, current));
        if ((previous.y > p.y) != (current.y > p.y)) {
            float crossing = previous.x + (p.y - previous.y) * (current.x - previous.x) / (current.y - previous.y);
            if (p.x < crossing) inside = !inside;
        }
        previous = current;
    }
    return inside ? -nearest : nearest;
}

vec4 dizzy_bird(vec2 p, float flap) {
    vec4 paint = vec4(0.0);
    float tail = min(dizzy_triangle(p, vec2(-3.4, 0.8), vec2(-10.0, -1.8), vec2(-6.3, 3.3)),
        dizzy_triangle(p, vec2(-3.4, 1.2), vec2(-9.0, 3.0), vec2(-5.8, 4.3)));
    paint = dizzy_over(paint, dizzy_ink(tail, theme_color(vec3(1.0, 0.66, 0.10), 0.5)));

    vec2 back_wing = dizzy_rotate(p - vec2(-0.5, -2.0), -0.65 - 0.40 * flap);
    float back = dizzy_oval(back_wing - vec2(0.0, -2.4), vec2(1.6, 3.4));
    paint = dizzy_over(paint, dizzy_ink(back, theme_color(vec3(1.0, 0.73, 0.17), 0.5)));

    float body = dizzy_oval(p - vec2(-0.6, 0.5), vec2(4.7, 3.4));
    float head = length(p - vec2(3.3, -2.3)) - 3.15;
    paint = dizzy_over(paint, dizzy_ink(min(body, head), theme_color(vec3(1.0, 0.88, 0.22), 0.5)));
    float belly = dizzy_oval(p - vec2(0.1, 1.8), vec2(2.8, 1.4));
    paint = dizzy_over(paint, dizzy_fill(belly, theme_color(vec3(1.0, 0.95, 0.58), 0.5)));

    vec2 wing = dizzy_rotate(p - vec2(-1.3, -0.2), 0.40 + 0.65 * flap);
    float front = dizzy_oval(wing - vec2(-1.0, -1.8), vec2(2.0, 3.5));
    paint = dizzy_over(paint, dizzy_ink(front, theme_color(vec3(1.0, 0.76, 0.12), 0.5)));
    float feather = dizzy_segment(wing, vec2(-1.6, -2.5), vec2(-0.8, -0.5)) - 0.24;
    paint = dizzy_over(paint, dizzy_fill(feather, theme_color(vec3(0.75, 0.40, 0.05), 0.5)));

    float beak = dizzy_triangle(p, vec2(5.2, -2.6), vec2(9.3, -0.9), vec2(5.1, -0.4));
    paint = dizzy_over(paint, dizzy_ink(beak, theme_color(vec3(1.0, 0.41, 0.07), 0.5)));
    paint = dizzy_over(paint, dizzy_fill(length(p - vec2(4.0, -3.0)) - 1.25, vec3(1.0)));
    paint = dizzy_over(paint, dizzy_fill(length(p - vec2(4.45, -2.9)) - 0.64, theme_color(vec3(0.09, 0.07, 0.055), 0.5)));
    paint = dizzy_over(paint, dizzy_fill(length(p - vec2(2.6, -1.0)) - 0.8, theme_color(vec3(1.0, 0.55, 0.26), 0.5)));
    return paint;
}

vec4 postprocess(vec3 coords) {
    vec4 under = tex2D_screen(coords.xy);
    vec2 p = (coords.xy * umbriel_output_size - umbriel_cursor) / max(umbriel_scale, 0.01);
    vec4 paint = vec4(0.0);
    if (length(p) < 5.0) paint = dizzy_ink(dizzy_star(p, 3.2), theme_color(vec3(1.0, 0.83, 0.22), 0.5));
    for (int i = 0; i < 6; i++) {
        float phase = float(i) * 1.04719755;
        float angle = umbriel_time * 1.15 + phase;
        vec2 center = vec2(54.0 * cos(angle), 39.0 * sin(angle));
        center.y += 2.0 * sin(umbriel_time * 3.0 + phase);
        vec2 local = p - center;
        if (length(local) > 16.0) continue;
        if (mod(float(i), 2.0) < 0.5) {
            // Birds keep upright and face along their direction of travel.
            local.x *= -sin(angle) >= 0.0 ? 1.0 : -1.0;
            local = dizzy_rotate(local, 0.15 * sin(angle * 2.0));
            float flap = sin(umbriel_time * 13.0 + phase * 2.0);
            paint = dizzy_over(paint, dizzy_bird(local, flap));
        } else {
            vec2 q = dizzy_rotate(local, umbriel_time * 1.8 + phase);
            float radius = 5.4 + 0.5 * sin(umbriel_time * 4.0 + phase);
            vec3 gold = mix(theme_color(vec3(1.0, 0.64, 0.06), 0.5), theme_color(vec3(1.0, 0.94, 0.42), 0.5), clamp(0.5 - q.y / 12.0, 0.0, 1.0));
            paint = dizzy_over(paint, dizzy_ink(dizzy_star(q, radius), gold));
            float glint = dizzy_segment(q, vec2(-1.0, -2.0), vec2(0.0, -3.8)) - 0.32;
            paint = dizzy_over(paint, dizzy_fill(glint, theme_color(vec3(1.0, 0.99, 0.83), 0.5)));
        }
    }
    return dizzy_over(under, paint);
}

vec4 cursor(vec2 uv) { return postprocess(vec3(uv, 0.0)); }
