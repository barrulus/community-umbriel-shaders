// Starlight by Barrulus. Untinted refraction and neutral drifting sparkles, based on Pond Wake.
// Time-aware curve interpolation adapted from the Noctalia trail / Comet.
const float WAKE_LIFE = 2.0;       // seconds, at most the retained history
const float REFRACTION = 2.0;      // logical pixels
const float SPREAD = 18.0;         // logical pixels per second
const float WAVELENGTH = 17.0;     // logical pixels
const float SPARK_STRENGTH = 0.55; // subtle neutral flashes

float starHash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
// nearest = distance, age; normal points away from the path.
void starSegment(vec2 pixel, vec4 p0, vec4 p1, vec4 p2, vec4 p3,
                 inout vec2 nearest, inout vec2 normal,
                 inout vec3 sparks) {
    vec2 a = p1.xy * umbriel_size;
    vec2 b = p2.xy * umbriel_size;
    vec2 chord = b - a;
    float chordLength = length(chord);
    // Ignore stationary samples and discontinuous pointer warps.
    if (chordLength < 0.05 || chordLength > 800.0 || p2.z >= WAKE_LIFE) return;
    float dt = max(p1.z - p2.z, 0.001);
    vec2 m0 = (b - p0.xy * umbriel_size) * dt / max(p0.z - p2.z, 0.001);
    vec2 m1 = (p3.xy * umbriel_size - a) * dt / max(p1.z - p3.z, 0.001);
    m0 *= min(1.0, 1.5 * chordLength / max(length(m0), 0.001));
    m1 *= min(1.0, 1.5 * chordLength / max(length(m1), 0.001));
    float bulge = (4.0 / 27.0) * (length(m0 - chord) + length(m1 - chord));
    vec2 rel = pixel - a;
    float projection = clamp(dot(rel, chord) / dot(chord, chord), 0.0, 1.0);
    float chordDistance = length(rel - chord * projection);
    if (chordDistance > 80.0 + bulge) return;
    // Persistent seeds give each droplet its own curl, size and flash timing.
    // Evaluate before nearest-path rejection so flashes survive crossing trails.
    vec2 tangent = chord / chordLength;
    vec2 sideways = vec2(-tangent.y, tangent.x);
    for (int n = 0; n < 2; ++n) {
        vec2 seed = vec2(p1.w * 13.7, float(n) * 37.0);
        float r = starHash(seed), s = starHash(seed + 17.3);
        if (r < 0.42) continue;
        float t = 0.15 + 0.7 * r;
        float age = mix(p1.z, p2.z, t);
        float life = smoothstep(0.02, 0.13, age) * (1.0-smoothstep(0.7, WAKE_LIFE, age));
        float turn = s * 6.2831853 + age * mix(-4.0, 4.0, r);
        float radius = (4.0 + 22.0*s) * smoothstep(0.0, 0.9, age);
        float t2 = t*t, t3 = t2*t;
        vec2 centre = (2.0*t3-3.0*t2+1.0)*a + (t3-2.0*t2+t)*m0
                    + (3.0*t2-2.0*t3)*b + (t3-t2)*m1;
        centre += sideways * sin(turn) * radius + tangent * cos(turn) * radius * 0.55;
        vec2 delta = pixel-centre;
        float distance2 = dot(delta,delta);
        if (distance2 > 324.0) continue;
        float flash = pow(max(sin(age*(5.0+9.0*s)+r*25.0), 0.0), 10.0);
        float core = exp(-distance2/(0.8+2.5*s));
        float halo = exp(-distance2/(18.0+45.0*s));
        vec2 q = vec2(dot(delta,tangent), dot(delta,sideways));
        float rays = exp(-abs(q.x)*2.5-abs(q.y)/4.5)
                   + exp(-abs(q.y)*2.5-abs(q.x)/4.5);
        float light = life * (core*(0.3+flash) + halo*(0.025+0.12*flash) + rays*flash*0.30);
        sparks = max(sparks, vec3(light));
    }
    if (chordDistance > nearest.x + bulge) return;
    vec2 previous = a;
    for (int j = 1; j <= 6; ++j) {
        float t = float(j) / 6.0;
        float t2 = t * t;
        float t3 = t2 * t;
        vec2 point = (2.0*t3 - 3.0*t2 + 1.0)*a + (t3 - 2.0*t2 + t)*m0
                   + (3.0*t2 - 2.0*t3)*b + (t3 - t2)*m1;
        vec2 piece = point - previous;
        float u = clamp(dot(pixel - previous, piece) / max(dot(piece, piece), 0.001), 0.0, 1.0);
        vec2 offset = pixel - mix(previous, point, u);
        float distance = length(offset);
        if (distance < nearest.x) {
            float along = (float(j) - 1.0 + u) / 6.0;
            nearest = vec2(distance, mix(p1.z, p2.z, along));
            normal = offset / max(distance, 0.5);
        }
        previous = point;
    }
}

vec4 cursor(vec2 uv) {
    vec4 background = umbriel_sample(uv);
    if (umbriel_pointer_count < 2) return background;
    vec2 nearest = vec2(80.0, WAKE_LIFE);
    vec2 normal = vec2(0.0);
    vec3 sparks = vec3(0.0);
    vec4 p0 = vec4(0.0), p1 = p0, p2 = p0, p3 = p0;
    for (int k = 0; k < 64; ++k) {
        if (k < umbriel_pointer_count) {
            vec4 next = umbriel_pointer_path[k];
            if (k == 0) { p1 = next; p2 = next; p3 = next; }
            p0 = p1; p1 = p2; p2 = p3; p3 = next;
            if (k >= 2) starSegment(uv * umbriel_size, p0, p1, p2, p3, nearest, normal, sparks);
        }
    }
    starSegment(uv * umbriel_size, p1, p2, p3, p3, nearest, normal, sparks);
    float d = nearest.x;
    float age = nearest.y;
    float life = 1.0 - smoothstep(0.5, WAKE_LIFE, age);
    if (life <= 0.0) return background;
    float tip = smoothstep(3.0, 15.0, length((uv - umbriel_pointer) * umbriel_size));
    float edge = 1.0 - smoothstep(65.0, 80.0, d);
    float front = 4.0 + SPREAD * age;
    float width = 8.0 + age * 5.0;
    float envelope = exp(-pow((d - front) / width, 2.0));
    float phase = (d - front) * 6.2831853 / WAVELENGTH;
    // Outward-moving wavelets bend the actual desktop, like a shallow water surface.
    float wave = sin(phase) * envelope;
    float furrow = sin(d * 0.23) * exp(-d*d / 160.0) * exp(-age * 2.0);
    vec2 displacement = normal * (wave + 0.35 * furrow) * REFRACTION * life * tip * edge;
    // Keep samples in bounds at output edges; no transparent fringe.
    vec2 halfPixel = 0.5 / (umbriel_size * max(umbriel_scale, 0.001));
    vec4 water = umbriel_sample(clamp(uv + displacement / umbriel_size, halfPixel, vec2(1.0) - halfPixel));
    // Equal RGB strength adds white glints without a coloured cloud or crest tint.
    vec3 flashLight = clamp(sparks * SPARK_STRENGTH * tip, 0.0, 0.75);
    vec3 colour = water.rgb*(1.0-flashLight) + flashLight*water.a;
    return vec4(colour, water.a);
}
