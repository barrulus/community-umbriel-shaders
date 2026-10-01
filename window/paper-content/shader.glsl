// Adapted from shaders/paper/window/crumpled-paper.glsl
vec4 tex2D_screen(vec2 uv) { return umbriel_sample(uv); }
vec2 migration_buffer_size() { return umbriel_size * umbriel_scale; }
#define umbriel_size migration_buffer_size()
const float PAPER_RELIEF = 0.24;
const float PAPER_DESATURATION = 0.85;

float paper_grain(vec2 p) {
    p = fract(p * vec2(123.34, 345.45));
    p += dot(p, p + 34.345);
    return fract(p.x * p.y);
}

vec2 paper_hash(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    q += dot(q, q.yzx + 33.33);
    return fract((q.xx + q.yz) * q.zy);
}

float paper_noise(vec2 p) {
    vec2 cell = floor(p);
    vec2 f = fract(p);
    vec2 blend = f * f * (3.0 - 2.0 * f);
    return mix(mix(paper_hash(cell).x, paper_hash(cell + vec2(1.0, 0.0)).x, blend.x),
        mix(paper_hash(cell + vec2(0.0, 1.0)).x, paper_hash(cell + vec2(1.0)).x, blend.x), blend.y);
}

// Irregular neighbouring facets meet in creases with opposing light and shade.
float paper_facets(vec2 p) {
    vec2 cell = floor(p);
    vec2 local = fract(p);
    float first = 100.0;
    float second = 100.0;
    vec2 nearest = vec2(0.0);
    vec2 neighbour = vec2(0.0);
    vec2 seed = vec2(0.0);
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 offset = vec2(float(x), float(y));
            vec2 random = paper_hash(cell + offset);
            vec2 delta = offset + 0.08 + 0.84 * random - local;
            float distance_squared = dot(delta, delta);
            if (distance_squared < first) {
                second = first;
                neighbour = nearest;
                first = distance_squared;
                nearest = delta;
                seed = random;
            } else if (distance_squared < second) {
                second = distance_squared;
                neighbour = delta;
            }
        }
    }
    vec2 across = neighbour - nearest;
    float separation = max(length(across), 0.001);
    float edge = max((second - first) / (2.0 * separation), 0.0);
    float light = dot(across / separation, normalize(vec2(-0.6, -0.8)));
    float strength = 0.55 + 0.45 * paper_noise(p * 0.61 + vec2(9.2, 3.7));
    float valley = exp(-edge * 85.0) * 0.30;
    float shoulder = exp(-edge * 16.0) * light * 0.48;
    float facet = dot(nearest, seed - 0.5) * 0.18;
    return (shoulder - valley + facet) * strength;
}

float paper_relief(vec2 p) {
    // Slow domain warping breaks the underlying cells into uneven fold sizes.
    vec2 warp = vec2(paper_noise(p / 117.0 + vec2(7.1, 2.8)),
        paper_noise(p / 139.0 + vec2(31.7, 19.2))) - 0.5;
    vec2 q = p + warp * 78.0;
    float large = paper_facets(q / 79.0);
    vec2 rotated = mat2(0.8, -0.6, 0.6, 0.8) * q;
    float small = paper_facets(rotated / 34.0 + vec2(43.3, 17.1));
    float fine_weight = 0.20 + 0.30 * paper_noise(p / 93.0 + vec2(15.0));
    return large + small * fine_weight + (paper_noise(q / 157.0) - 0.5) * 0.16;
}

vec4 postprocess(vec3 coords) {
    vec4 source = tex2D_screen(coords.xy);
    if (source.a <= 0.0) return source;
    vec2 p = coords.xy * umbriel_size / max(umbriel_scale, 0.01);
    vec3 color = source.rgb / source.a;
    float luminance = dot(color, vec3(0.299, 0.587, 0.114));
    color = mix(color, vec3(luminance), PAPER_DESATURATION);
    // Lift black backgrounds just enough to show the paper's relief, while
    // keeping their light text light. Neutral endpoints and crease lighting
    // keep the sheet white instead of tinting it pink or cream.
    color = mix(vec3(0.095), vec3(0.985), color);
    float fibre = (paper_grain(floor(p * 1.6)) - 0.5) * 0.018;
    float relief = paper_relief(p) * PAPER_RELIEF;
    color = color * (1.0 + relief) + vec3(relief * 0.12 + fibre);
    return vec4(clamp(color, 0.0, 1.0) * source.a, source.a);
}

vec4 window(vec2 uv) { return postprocess(vec3(uv, 0.0)); }
