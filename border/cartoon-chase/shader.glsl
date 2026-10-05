// Adapted from shaders/rings/cartoon-chase.glsl

// Theme colours affect artwork only; palette = false restores the original RGB.
// Keep the original shade and soften highlights without changing effect opacity.
vec3 theme_color(vec3 original, float position) {
    if (umbriel_palette_count <= 0) return original;
    float value = max(original.r, max(original.g, original.b));
    float white = min(original.r, min(original.g, original.b)) / max(value, 0.0001);
    return value * mix(umbriel_palette_at(position).rgb, vec3(1.0), white * 0.75);
}

#define ring_padding 48.0
#define ring_size (umbriel_border_hole.zw * umbriel_size)
#define ring_width max((1.0 - umbriel_border_hole.w) * umbriel_size.y * 0.5 - ring_padding, 1.0)
#define ring_radius umbriel_border_radius
float ring_distance(vec2 coords) { return umbriel_border_distance(coords / umbriel_size + umbriel_border_hole.xy); }
// Bodies face into the window; spinning feet and fading dust ride its edge.
const float CHASE_PI = 3.14159265359;
const float CHASE_INSET = 64.0;

float chase_scale() { return min(1.0, min(ring_size.x, ring_size.y) / 180.0); }
float chase_margin() { return 1.0 * chase_scale(); }
vec2 chase_track_size() { return ring_size - 2.0 * chase_margin(); }
float chase_radius() {
    vec2 track = chase_track_size();
    return min(26.0 * chase_scale(), min(track.x, track.y) * 0.25);
}
float chase_perimeter() {
    vec2 track = chase_track_size();
    return 2.0 * (track.x + track.y) - (8.0 - 2.0 * CHASE_PI) * chase_radius();
}

vec4 chase_frame(float along) {
    vec2 track = chase_track_size();
    vec2 origin = vec2(chase_margin());
    float r = chase_radius();
    float s = mod(along, chase_perimeter());
    for (int side = 0; side < 4; side++) {
        float line;
        vec2 start, tangent, center;
        if (side == 0) {
            line = track.x - 2.0 * r;
            start = vec2(r, 0.0); tangent = vec2(1.0, 0.0); center = vec2(track.x - r, r);
        } else if (side == 1) {
            line = track.y - 2.0 * r;
            start = vec2(track.x, r); tangent = vec2(0.0, 1.0); center = track - r;
        } else if (side == 2) {
            line = track.x - 2.0 * r;
            start = vec2(track.x - r, track.y); tangent = vec2(-1.0, 0.0); center = vec2(r, track.y - r);
        } else {
            line = track.y - 2.0 * r;
            start = vec2(0.0, track.y - r); tangent = vec2(0.0, -1.0); center = vec2(r);
        }
        if (s <= line) return vec4(origin + start + tangent * s, tangent);
        s -= line;
        float arc = CHASE_PI * r * 0.5;
        if (s <= arc || side == 3) {
            float angle = (float(side) - 1.0) * CHASE_PI * 0.5 + s / max(r, 0.001);
            return vec4(origin + center + r * vec2(cos(angle), sin(angle)), -sin(angle), cos(angle));
        }
        s -= arc;
    }
    return vec4(origin + vec2(r, 0.0), 1.0, 0.0);
}

vec4 chase_over(vec4 under, vec4 paint) {
    return paint + under * (1.0 - paint.a);
}

vec2 chase_rotate(vec2 p, float angle) {
    float c = cos(angle), s = sin(angle);
    return vec2(c * p.x + s * p.y, -s * p.x + c * p.y);
}

float chase_oval(vec2 p, vec2 radius) {
    return (length(p / radius) - 1.0) * min(radius.x, radius.y);
}

float chase_segment(vec2 p, vec2 a, vec2 b) {
    vec2 edge = b - a;
    return length(p - a - edge * clamp(dot(p - a, edge) / dot(edge, edge), 0.0, 1.0));
}

float chase_cross(vec2 a, vec2 b) {
    return a.x * b.y - a.y * b.x;
}

float chase_triangle(vec2 p, vec2 a, vec2 b, vec2 c) {
    float distance = min(chase_segment(p, a, b), min(chase_segment(p, b, c), chase_segment(p, c, a)));
    float x = chase_cross(b - a, p - a);
    float y = chase_cross(c - b, p - b);
    float z = chase_cross(a - c, p - c);
    bool inside = (x >= 0.0 && y >= 0.0 && z >= 0.0) || (x <= 0.0 && y <= 0.0 && z <= 0.0);
    return inside ? -distance : distance;
}

vec4 chase_fill(float distance, vec3 color) {
    float aa = 0.65 / max(umbriel_scale, 0.01);
    float alpha = 1.0 - smoothstep(-aa, aa, distance);
    return vec4(color * alpha, alpha);
}

vec4 chase_ink(float distance, vec3 color) {
    vec4 edge = chase_fill(distance - 0.65, theme_color(vec3(0.16, 0.09, 0.045), 0.5));
    return chase_over(edge, chase_fill(distance + 0.10, color));
}

vec4 chase_runner(vec2 p, float time) {
    vec4 paint = vec4(0.0);
    float stride = sin(time * 22.0);
    vec3 blue = theme_color(vec3(0.18, 0.45, 0.88), 0.25);
    vec3 navy = theme_color(vec3(0.12, 0.24, 0.56), 0.25);
    vec3 gold = theme_color(vec3(1.0, 0.62, 0.12), 0.5);

    float tail = min(chase_triangle(p, vec2(-3.0, -12.0), vec2(-27.0, -24.0), vec2(-15.0, -11.0)),
        chase_triangle(p, vec2(-5.0, -12.0), vec2(-28.0, -17.0), vec2(-17.0, -8.0)));
    paint = chase_over(paint, chase_ink(tail, navy));
    paint = chase_over(paint, chase_fill(chase_segment(p, vec2(-9.0, -13.0), vec2(-23.0, -20.0)) - 0.45, blue));

    float body = chase_oval(p - vec2(-2.0, -11.0), vec2(8.0, 4.5));
    float neck = chase_segment(p, vec2(3.0, -11.0), vec2(7.0, -22.0)) - 2.5;
    float head = chase_oval(p - vec2(9.0, -23.0), vec2(5.0, 3.8));
    paint = chase_over(paint, chase_ink(min(body, min(neck, head)), blue));
    float breast = chase_segment(p, vec2(5.0, -12.0), vec2(8.4, -20.0)) - 1.25;
    paint = chase_over(paint, chase_fill(breast, theme_color(vec3(0.61, 0.83, 1.0), 0.25)));
    paint = chase_over(paint, chase_ink(chase_oval(p - vec2(-3.5, -12.0), vec2(5.0, 2.5)), navy));
    for (int i = 0; i < 3; i++) {
        float k = float(i);
        float crest = chase_triangle(p, vec2(5.5 + k * 1.4, -25.0), vec2(0.5 + k * 2.0, -33.0 + k), vec2(9.0 + k, -25.0));
        paint = chase_over(paint, chase_ink(crest, navy));
    }
    float beak = chase_triangle(p, vec2(12.0, -24.0), vec2(24.0, -20.5), vec2(11.5, -20.0));
    paint = chase_over(paint, chase_ink(beak, gold));
    paint = chase_over(paint, chase_fill(chase_oval(p - vec2(10.0, -23.5), vec2(1.8, 2.4)), vec3(1.0)));
    paint = chase_over(paint, chase_fill(length(p - vec2(10.8, -23.4)) - 0.85, theme_color(vec3(0.06, 0.07, 0.10), 0.25)));
    return paint;
}

vec4 chase_coyote(vec2 p, float time) {
    vec4 paint = vec4(0.0);
    vec3 fur = theme_color(vec3(0.56, 0.34, 0.17), 0.5);
    vec3 tan = theme_color(vec3(0.91, 0.74, 0.48), 0.5);
    float stride = sin(time * 18.0);
    float tail = min(chase_triangle(p, vec2(-6.0, -13.0), vec2(-23.0, -6.0), vec2(-14.0, -3.0)),
        chase_oval(chase_rotate(p - vec2(-12.0, -9.0), -0.6), vec2(9.0, 3.2)));
    paint = chase_over(paint, chase_ink(tail, fur));
    paint = chase_over(paint, chase_fill(chase_triangle(p, vec2(-20.0, -9.0), vec2(-24.0, -5.0), vec2(-17.0, -4.0)), tan));
    float body = chase_oval(chase_rotate(p - vec2(-1.0, -14.0), 0.24), vec2(5.5, 9.0));
    float head = chase_oval(p - vec2(6.0, -23.0), vec2(5.0, 5.0));
    paint = chase_over(paint, chase_ink(min(body, head), fur));
    paint = chase_over(paint, chase_fill(chase_oval(p - vec2(1.0, -13.0), vec2(2.8, 6.0)), tan));
    float ear = min(chase_triangle(p, vec2(1.4, -26.0), vec2(-0.5, -38.0), vec2(6.0, -28.0)),
        chase_triangle(p, vec2(6.2, -27.0), vec2(9.5, -39.0), vec2(10.7, -24.0)));
    paint = chase_over(paint, chase_ink(ear, fur));
    float inner_ear = min(chase_triangle(p, vec2(2.4, -28.0), vec2(1.1, -34.7), vec2(4.4, -28.7)),
        chase_triangle(p, vec2(7.4, -27.5), vec2(9.1, -35.0), vec2(9.3, -27.0)));
    paint = chase_over(paint, chase_fill(inner_ear, theme_color(vec3(0.78, 0.52, 0.35), 0.5)));
    float muzzle = chase_oval(chase_rotate(p - vec2(11.0, -20.5), 0.12), vec2(7.4, 2.9));
    paint = chase_over(paint, chase_ink(muzzle, tan));
    paint = chase_over(paint, chase_ink(chase_oval(p - vec2(17.5, -21.0), vec2(2.1, 1.9)), theme_color(vec3(0.12, 0.09, 0.08), 0.75)));
    paint = chase_over(paint, chase_fill(chase_oval(p - vec2(7.7, -24.1), vec2(2.2, 2.7)), theme_color(vec3(1.0, 0.96, 0.80), 0.5)));
    paint = chase_over(paint, chase_fill(length(p - vec2(8.6, -23.8)) - 0.8, vec3(0.08)));
    paint = chase_over(paint, chase_fill(chase_segment(p, vec2(5.4, -26.5), vec2(10.0, -25.2)) - 0.65, theme_color(vec3(0.17, 0.10, 0.05), 0.5)));
    float arm = min(chase_segment(p, vec2(2.0, -17.0), vec2(8.0, -11.0 + stride * 2.0)),
        chase_segment(p, vec2(8.0, -11.0 + stride * 2.0), vec2(14.0, -15.0 + stride * 2.0))) - 1.3;
    paint = chase_over(paint, chase_ink(arm, fur));
    paint = chase_over(paint, chase_ink(chase_oval(p - vec2(14.0, -15.0 + stride * 2.0), vec2(2.6, 1.8)), tan));
    return paint;
}

vec4 chase_devil(vec2 p, float time) {
    vec4 paint = vec4(0.0);
    float spin = time * 23.0;
    // A tapered whirlwind with fast, uneven bands and a face flashing through it.
    float height = clamp((4.0 - p.y) / 34.0, 0.0, 1.0);
    float radius = 3.0 + 12.0 * height + 1.0 * sin(p.y * 0.8 - spin);
    float cone = max(abs(p.x) - radius, max(p.y - 4.0, -30.0 - p.y));
    float stripe = 0.5 + 0.5 * sin(p.y * 1.15 - spin + p.x * 0.10);
    vec3 brown = mix(theme_color(vec3(0.36, 0.17, 0.075), 0.5), theme_color(vec3(0.79, 0.50, 0.24), 0.5), stripe);
    paint = chase_over(paint, chase_ink(cone, brown));
    for (int i = 0; i < 4; i++) {
        float k = float(i);
        float y = -3.0 - k * 7.0;
        float rx = 5.0 + k * 3.2;
        float swirl = abs(chase_oval(p - vec2(sin(spin + k) * 1.5, y), vec2(rx, 2.5))) - 0.48;
        paint = chase_over(paint, chase_fill(swirl, theme_color(vec3(0.95, 0.73, 0.43), 0.5)));
    }
    float face_alpha = smoothstep(-0.25, 0.45, cos(time * 9.0));
    vec2 q = vec2(p.x / (0.80 + 0.20 * abs(cos(time * 9.0))), p.y);
    vec4 face = vec4(0.0);
    float cheeks = chase_oval(q - vec2(0.0, -18.0), vec2(10.7, 8.8));
    face = chase_over(face, chase_ink(cheeks, theme_color(vec3(0.88, 0.66, 0.40), 0.5)));
    float ears = min(chase_triangle(q, vec2(-12.0, -27.0), vec2(-9.0, -35.0), vec2(-4.0, -28.0)),
        chase_triangle(q, vec2(4.0, -28.0), vec2(9.0, -35.0), vec2(12.0, -27.0)));
    face = chase_over(face, chase_ink(ears, theme_color(vec3(0.43, 0.23, 0.10), 0.5)));
    float mouth = chase_oval(q - vec2(0.0, -15.0), vec2(7.7, 6.3));
    face = chase_over(face, chase_ink(mouth, theme_color(vec3(0.17, 0.055, 0.035), 0.75)));
    for (int i = 0; i < 2; i++) {
        float x = i == 0 ? -4.5 : 4.5;
        float tooth = chase_triangle(q, vec2(x - 1.6, -19.5), vec2(x + 1.6, -19.5), vec2(x, -14.3));
        face = chase_over(face, chase_fill(tooth, theme_color(vec3(1.0, 0.97, 0.84), 0.5)));
        float eye = chase_oval(q - vec2(x, -24.0), vec2(2.8, 2.2));
        face = chase_over(face, chase_ink(eye, theme_color(vec3(1.0, 0.96, 0.72), 0.5)));
        face = chase_over(face, chase_fill(length(q - vec2(x * 0.80, -23.9)) - 0.8, vec3(0.08)));
    }
    face = chase_over(face, chase_ink(chase_oval(q - vec2(0.0, -21.0), vec2(3.2, 1.8)), theme_color(vec3(0.12, 0.07, 0.04), 0.5)));
    paint = chase_over(paint, face * face_alpha);
    return paint;
}

// Nearest point on the rounded track: clockwise distance and outward depth.
vec2 chase_project(vec2 p) {
    vec2 track = chase_track_size(), origin = vec2(chase_margin());
    float r = chase_radius(), base = 0.0, best = 1.0e20;
    vec2 result = vec2(0.0);
    for (int side = 0; side < 4; side++) {
        vec4 frame;
        if (side == 0) frame = vec4(origin + vec2(r,0.0),1.0,0.0);
        else if (side == 1) frame = vec4(origin + vec2(track.x,r),0.0,1.0);
        else if (side == 2) frame = vec4(origin + vec2(track.x-r,track.y),-1.0,0.0);
        else frame = vec4(origin + vec2(0.0,track.y-r),0.0,-1.0);
        float line = (side == 0 || side == 2 ? track.x : track.y) - 2.0 * r;
        float t = clamp(dot(p - frame.xy, frame.zw), 0.0, line);
        vec2 delta = p - frame.xy - frame.zw * t;
        float d2 = dot(delta, delta);
        if (d2 < best) {
            best = d2;
            result = vec2(base + t, dot(delta, vec2(frame.w, -frame.z)));
        }
        base += line;
        vec2 center;
        if (side == 0) center = vec2(track.x - r, r);
        else if (side == 1) center = track - r;
        else if (side == 2) center = vec2(r, track.y - r);
        else center = vec2(r);
        delta = p - origin - center;
        float start = (float(side) - 1.0) * CHASE_PI * 0.5;
        float angle = mod(atan(delta.y, delta.x) - start + CHASE_PI, 2.0 * CHASE_PI) - CHASE_PI;
        angle = clamp(angle, 0.0, CHASE_PI * 0.5);
        vec2 outward = vec2(cos(start + angle), sin(start + angle));
        vec2 diff = delta - r * outward;
        d2 = dot(diff, diff);
        if (d2 < best) {
            best = d2;
            result = vec2(base + angle * r, dot(diff, outward));
        }
        base += CHASE_PI * r * 0.5;
    }
    return result;
}

vec4 chase_speed_legs(vec2 p, float time, float lift, vec3 color) {
    // Compressed whirling disks occupy only the narrow focus-ring band.
    vec2 center = vec2(-1.0, 1.0);
    vec2 q = (p - center) / vec2(10.0, 3.4);
    float radius = length(q), angle = atan(q.y, q.x);
    vec4 paint = chase_fill(chase_segment(p, vec2(-1.0, -7.0-lift), center) - 1.0, color);
    float blur = (1.0 - smoothstep(0.72, 1.14, radius)) * 0.30;
    paint = chase_over(paint, vec4(color * blur, blur));
    float spokes = pow(0.5 + 0.5 * cos(angle * 5.0 - time * 65.0 + radius * 2.0), 7.0);
    float spin = spokes * smoothstep(0.15, 0.42, radius) * (1.0 - smoothstep(0.86, 1.06, radius));
    paint = chase_over(paint, vec4(color * spin, spin) * 0.88);
    float rim = abs(chase_oval(p-center, vec2(10.0, 3.4))) - 0.30;
    float flicker = 0.42 + 0.25 * sin(angle * 3.0 - time * 39.0);
    paint = chase_over(paint, chase_fill(rim, mix(color, theme_color(vec3(1.0,0.94,0.72), 0.5),0.4)) * flicker);
    return paint;
}

float chase_hash(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * 0.1031);
    q += dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z);
}
float chase_noise(vec2 p) {
    vec2 cell = floor(p), f = fract(p);
    f = f*f*(3.0-2.0*f);
    return mix(mix(chase_hash(cell),chase_hash(cell+vec2(1.0,0.0)),f.x),
               mix(chase_hash(cell+vec2(0.0,1.0)),chase_hash(cell+vec2(1.0)),f.x),f.y);
}

vec4 ring_color(vec2 coords) {
    float inner = min(min(coords.x, coords.y), min(ring_size.x - coords.x, ring_size.y - coords.y));
    if (inner > CHASE_INSET || inner < -12.0 || min(ring_size.x, ring_size.y) <= 0.0) return vec4(0.0);
    float perimeter = chase_perimeter();
    float lead = umbriel_time * 210.0 + perimeter * 0.12;
    float sprite_scale = chase_scale();
    vec2 track = vec2(0.0,100.0);
    if (inner < 14.0) track = chase_project(coords);
    vec4 paint = vec4(0.0);
    // A thin dusty wake makes the border itself, fading over almost a full lap.
    if (abs(track.y) < 8.0) {
        for (int i = 0; i < 3; i++) {
            float along = lead;
            if (i == 1) along -= min(160.0, perimeter * 0.22);
            if (i == 2) along = umbriel_time * 340.0 + perimeter * 0.64;
            float behind = mod(along - track.x, perimeter);
            float age = behind / perimeter;
            float fade = exp(-2.8 * age) * (1.0 - smoothstep(0.78, 0.98, age));
            fade *= smoothstep(0.0, 14.0 * sprite_scale, behind);
            vec2 dust_uv = coords * 0.24 + vec2(-umbriel_time*0.8,umbriel_time*0.35) + float(i)*17.3;
            float grain = 0.65 * chase_noise(dust_uv) + 0.35 * chase_noise(dust_uv*2.71+9.1);
            float drift = (chase_noise(coords*0.055+umbriel_time*0.3+float(i)*7.1)-0.5)*1.8;
            float width = 1.1 + 1.0 * grain + 0.7 * age;
            float across = abs(track.y - 1.0 - drift);
            float cloud = exp(-across * across / (width * width)) * (0.30 + 0.25 * grain);
            float mote = exp(-across * across / 12.0) * pow(max(grain,0.0),5.0) * 0.18;
            float alpha = (cloud + mote) * fade;
            vec3 dust = mix(theme_color(vec3(0.68,0.46,0.24), 0.5),theme_color(vec3(0.97,0.84,0.59), 0.5),grain);
            paint = chase_over(paint, vec4(dust * alpha, alpha));
        }
    }
    for (int i = 0; i < 3; i++) {
        float along = lead;
        if (i == 1) along -= min(160.0, perimeter * 0.22);
        if (i == 2) along = umbriel_time * 340.0 + perimeter * 0.64;
        vec4 frame = chase_frame(along);
        vec2 normal = vec2(frame.w, -frame.z);
        vec2 delta = coords - frame.xy;
        // Negative artwork y now points INWARD: heads in the client, feet on its edge.
        vec2 p = vec2(dot(delta, frame.zw), dot(delta, normal)) / sprite_scale;
        if (abs(p.x) > 31.0 || p.y < -62.0 || p.y > 8.0) continue;
        // A small lift only while rounding corners keeps ears and tails in frame.
        float lift = 16.0 * abs(frame.z * frame.w) * 2.0;
        if (i < 2) {
            vec3 legs = i == 0 ? theme_color(vec3(1.0,0.66,0.18), 0.5) : theme_color(vec3(0.89,0.69,0.42), 0.5);
            paint = chase_over(paint, chase_speed_legs(p,umbriel_time,lift,legs));
        }
        vec2 body = p;
        body.y += lift + 0.7 * abs(sin(umbriel_time * 18.0));
        vec4 sprite;
        if (i == 0) sprite = chase_runner(body, umbriel_time);
        else if (i == 1) sprite = chase_coyote(body, umbriel_time);
        else {
            body.y = p.y + lift * clamp(-p.y / (18.0 + lift), 0.0, 1.0);
            sprite = chase_devil(body, umbriel_time);
        }
        paint = chase_over(paint, sprite);
    }
    return vec4(paint.rgb / max(paint.a, 0.0001), paint.a);
}

vec4 border(vec2 uv) {
    vec4 c = ring_color((uv - umbriel_border_hole.xy) * umbriel_size);
    return vec4(c.rgb * c.a, c.a);
}
