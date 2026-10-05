// Pond Wake by Barrulus. Ripple refraction follows the retained pointer path.
// Time-aware curve interpolation adapted from the Noctalia trail / Comet.
const float WAKE_LIFE = 2.0;       // seconds, at most the retained history
const float REFRACTION = 4.5;      // logical pixels
const float SPREAD = 18.0;         // logical pixels per second
const float WAVELENGTH = 17.0;     // logical pixels
const float BIO_GLOW = 0.72;       // luminous swirling cloud strength
const float SPARK_STRENGTH = 0.90; // irregular fairy-like flashes
const float CREST_LIGHT = 0.025;
const vec3 BIO_COLOUR = vec3(0.12, 0.85, 0.72);

float pondHash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float pondNoise(vec2 p) {
    vec2 cell = floor(p), f = fract(p);
    f = f*f*(3.0-2.0*f);
    return mix(mix(pondHash(cell), pondHash(cell+vec2(1.0,0.0)), f.x),
               mix(pondHash(cell+vec2(0.0,1.0)), pondHash(cell+vec2(1.0)), f.x), f.y);
}

// nearest = distance, age, birth phase; normal points away from the path.
void pondSegment(vec2 pixel, vec4 p0, vec4 p1, vec4 p2, vec4 p3,
                 inout vec3 nearest, inout vec2 normal, inout float across,
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
        float r = pondHash(seed), s = pondHash(seed + 17.3);
        if (r < 0.28) continue;
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
        float light = life * (core*(0.3+flash) + halo*(0.08+0.30*flash) + rays*flash*0.45);
        vec3 colour = mix(vec3(0.12,0.65,1.0), vec3(0.65,1.0,0.78), s);
        colour = mix(colour, vec3(0.88,1.0,0.98), flash*0.7);
        sparks = max(sparks, colour*light);
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
            // Birth phase wraps at 60 s; unwrap before interpolating the newest sample.
            float birth = p1.w + mod(p2.w - p1.w + 60.0, 60.0) * along;
            nearest = vec3(distance, mix(p1.z, p2.z, along), birth);
            normal = offset / max(distance, 0.5);
            across = dot(offset, sideways);
        }
        previous = point;
    }
}

vec4 cursor(vec2 uv) {
    vec4 background = umbriel_sample(uv);
    if (umbriel_pointer_count < 2) return background;
    vec3 nearest = vec3(80.0, WAKE_LIFE, 0.0);
    vec2 normal = vec2(0.0);
    float across = 0.0;
    vec3 sparks = vec3(0.0);
    vec4 p0 = vec4(0.0), p1 = p0, p2 = p0, p3 = p0;
    for (int k = 0; k < 64; ++k) {
        if (k < umbriel_pointer_count) {
            vec4 next = umbriel_pointer_path[k];
            if (k == 0) { p1 = next; p2 = next; p3 = next; }
            p0 = p1; p1 = p2; p2 = p3; p3 = next;
            if (k >= 2) pondSegment(uv * umbriel_size, p0, p1, p2, p3, nearest, normal, across, sparks);
        }
    }
    pondSegment(uv * umbriel_size, p1, p2, p3, p3, nearest, normal, across, sparks);
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
    // Embed birth phase on a circle, keeping clouds continuous at the 60 s wrap.
    float birthAngle = nearest.z * 6.2831853 / 60.0;
    vec2 flow = vec2(cos(birthAngle), sin(birthAngle)) * 180.0;
    flow += vec2(across * 0.065, across * 0.041);
    vec2 warp = vec2(pondNoise(flow + vec2(age*0.7, 8.1)),
                     pondNoise(flow + vec2(17.2, -age*0.8)));
    vec2 curl = flow + (warp-0.5)*4.5;
    float billow = pondNoise(curl*1.6 + vec2(-age*0.6, age*0.4));
    float lace = pondNoise(curl*3.2 + vec2(6.2, age));
    float wisps = pow(max(1.0-abs(billow-0.5)*5.0, 0.0), 2.0);
    float stirred = exp(-d*d / pow(13.0 + age * 13.0, 2.0));
    float bloom = smoothstep(0.0, 0.12, age) * life * tip * edge;
    float glow = BIO_GLOW * bloom * stirred * (0.12 + 0.88*wisps) * (0.4+0.6*lace);
    float crest = max(cos(phase), 0.0) * envelope * CREST_LIGHT * life * tip * edge;
    vec3 luminous = mix(vec3(0.12,0.45,1.0), BIO_COLOUR, smoothstep(0.2,0.8,billow));
    luminous = mix(luminous, vec3(0.55,1.0,0.85), wisps*lace*0.6);
    vec3 colour = mix(water.rgb, luminous * water.a, clamp(glow, 0.0, 0.85));
    vec3 flashLight = clamp(sparks * SPARK_STRENGTH * tip, 0.0, 0.95);
    colour = colour*(1.0-flashLight) + flashLight*water.a;
    colour += vec3(0.60, 0.85, 0.88) * crest * water.a;
    return vec4(colour, water.a);
}
