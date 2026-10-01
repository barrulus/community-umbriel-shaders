// Adapted from shaders/beach-surf/waves.glsl
vec2 surf_hash(vec2 p) {
    return fract(sin(vec2(dot(p, vec2(127.1, 311.7)),
        dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}

float surf_noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(surf_hash(i).x, surf_hash(i + vec2(1.0, 0.0)).x, f.x),
        mix(surf_hash(i + vec2(0.0, 1.0)).x, surf_hash(i + 1.0).x, f.x), f.y);
}

// Distance between the two nearest moving cells makes fine, irregular bubble
// walls. Fixed loop bounds work on GLES2; callers cull non-edge pixels first.
float surf_bubbles(vec2 p, float t) {
    p += 0.22 * sin(p.yx * vec2(1.3, 1.6) + vec2(t * 0.8, -t * 0.6));
    vec2 cell = floor(p), local = fract(p);
    float nearest = 8.0, second = 8.0;
    for (int y = -1; y <= 1; ++y) {
        for (int x = -1; x <= 1; ++x) {
            vec2 offset = vec2(float(x), float(y));
            vec2 random = surf_hash(cell + offset);
            vec2 centre = 0.5 + 0.32 * sin(t * 0.7 + 6.2831853 * random);
            float d = length(offset + centre - local);
            second = min(second, max(nearest, d));
            nearest = min(nearest, d);
        }
    }
    return 1.0 - smoothstep(0.055, 0.17, second - nearest);
}

vec3 surf_water(float noise, float light) {
    vec3 color = mix(vec3(0.018, 0.16, 0.22), vec3(0.055, 0.43, 0.48), noise);
    return mix(color, vec3(0.33, 0.68, 0.70), clamp(light, 0.0, 0.65));
}

// Straight RGBA. d is signed logical-pixel distance: negative is inside.
vec4 surf_edge(vec2 p, float d, float t, float aa) {
    if (d < -24.0 || d > 32.0) return vec4(0.0);
    vec2 drift = vec2(t * 0.31, -t * 0.23);
    float n = surf_noise(p * 0.035 + drift);
    float fine = surf_noise(p * 0.14 - drift * 1.3);
    float extent = 16.0 + 10.0 * n;
    float envelope = smoothstep(-24.0, -7.0, d)
        * (1.0 - smoothstep(extent - 3.0, extent, d));
    // Successive crests wash inward. The two sides share a time and palette,
    // rather than restarting the motion at each corner.
    float phase = (d + t * 9.0 + n * 7.0) / 16.0;
    float crestDistance = abs(fract(phase) - 0.5) * 16.0;
    float crest = 1.0 - smoothstep(1.8, 5.2 + aa, crestDistance);
    float bubbles = surf_bubbles(p * 0.18 + vec2(t * 0.48, -t * 0.32), t);
    float lace = bubbles * smoothstep(0.30, 0.66, fine)
        * (0.35 + 0.65 * (1.0 - smoothstep(1.0, 6.0, crestDistance)));
    float foam = clamp(crest * (0.45 + 0.35 * fine + 0.20 * bubbles) + lace * 0.7, 0.0, 1.0);
    foam *= mix(0.50, 1.0, smoothstep(0.25, 0.65, n));
    float alpha = envelope * (0.25 + foam * 0.70);
    // The inner wash stays translucent; the outer breakers remain bright.
    alpha *= mix(0.50, 1.0, smoothstep(-12.0, 1.0, d));
    vec3 color = mix(surf_water(n, crest * 0.3), vec3(0.88, 0.97, 0.94), foam);
    return vec4(color, clamp(alpha, 0.0, 1.0));
}

// Two opposing top-view breakers form the window. Closing pulls the water
// toward all four corners. Use for both open and close, 2450 ms, linear.
vec4 animation(vec2 uv) {
    float t = clamp(umbriel_linear_progress, 0.0, 1.0);
    bool opening = umbriel_direction > 0.0;
    if (t <= 0.0) return opening ? vec4(0.0) : umbriel_sample(uv);
    if (t >= 1.0) return opening ? umbriel_sample(uv) : vec4(0.0);
    vec2 size = max(umbriel_size, vec2(1.0));
    float unit = min(size.x, size.y);
    vec2 aspect = size / unit;
    vec2 p = uv * aspect;
    vec2 pixels = uv * size;
    float aa = 1.25 / unit;
    float seed = umbriel_random_seed.x * 13.0;
    float time = t * 4.0;
    float n = surf_noise(p * 12.0 + vec2(seed, -time));
    float fine = surf_noise(p * 49.0 + vec2(time, seed));
    float boundary;
    float visible;
    float material;
    float foamLife;
    vec2 sourceUV = uv;

    if (opening) {
        // Broad wavefronts travel from the left and right edges to the centre.
        // Different scalloping on each side avoids a mirrored curtain wipe.
        float side = uv.x < 0.5 ? -1.0 : 1.0;
        float coast = sin(p.y * 16.0 + seed + side * 1.4) * 0.016
            + (n - 0.5) * 0.033;
        float arrival = smoothstep(0.02, 0.72, t);
        float front = mix(-0.001, aspect.x * 0.55, arrival);
        float fromEdge = min(p.x, aspect.x - p.x);
        boundary = fromEdge - front + coast * sin(arrival * 3.14159265);
        visible = (1.0 - smoothstep(-aa, aa, boundary)) * smoothstep(0.0, 0.07, t);
        // Colour resolves behind each breaker, with a final clear-water settle.
        float passed = smoothstep(0.025, 0.22, -boundary);
        material = passed * smoothstep(0.32, 0.94, t);
        foamLife = 1.0 - smoothstep(0.72, 0.98, t);
        float bend = exp(-abs(boundary) / 0.075) * 0.035 * foamLife;
        sourceUV.x += side * bend;
        sourceUV.y += sin(p.y * 24.0 - time * 4.0) * bend * 0.25;
    } else {
        // Each quadrant drains toward its own corner. Curved retreating fronts
        // break the sheet into four pools, then little splashes at the corners.
        float drain = smoothstep(0.13, 0.95, t);
        vec2 cornerSpace = min(uv, 1.0 - uv) * aspect;
        vec2 centre = mix(aspect * 0.24, vec2(0.028), drain);
        float radius = mix(length(aspect) * 0.58, 0.008, drain);
        boundary = length(cornerSpace - centre) - radius;
        boundary += (n - 0.5) * 0.032 * sin(drain * 3.14159265);
        visible = (1.0 - smoothstep(-aa, aa, boundary))
            * (1.0 - smoothstep(0.87, 1.0, t));
        material = 1.0 - smoothstep(0.0, 0.32, t);
        foamLife = smoothstep(0.0, 0.20, t) * (1.0 - smoothstep(0.86, 1.0, t));
        vec2 direction = sign(uv - 0.5);
        sourceUV -= direction * drain * 0.12 * (1.0 - drain);
        sourceUV += vec2(sin(p.y * 31.0 + time), cos(p.x * 29.0 - time)) * 0.018 * foamLife;
    }

    vec4 source = umbriel_sample(clamp(sourceUV, vec2(0.001), vec2(0.999)));
    float bubbles = surf_bubbles(p * 92.0 + vec2(time * 0.7, -time), time);
    float breaking = 1.0 - smoothstep(0.0, 0.045, abs(boundary));
    float wake = (1.0 - smoothstep(0.02, 0.16, -boundary)) * step(boundary, 0.0);
    float foam = breaking * (0.55 + fine * 0.45)
        + wake * bubbles * smoothstep(0.22, 0.65, fine) * 0.60;
    float caustic = pow(0.5 + 0.5 * sin(p.y * 55.0 + n * 9.0 - time * 5.0), 8.0);
    vec3 color = surf_water(n, caustic * 0.45);
    color = mix(color, vec3(0.88, 0.97, 0.94), clamp(foam * foamLife, 0.0, 1.0));
    vec4 water = vec4(color * source.a, source.a);
    vec4 result = mix(water, source, material) * visible;

    // Foam breaks against the rectangular mould as the water arrives.
    float edge = min(min(pixels.x, pixels.y), min(size.x - pixels.x, size.y - pixels.y));
    if (edge < 24.0) {
        vec4 froth = surf_edge(pixels, -edge, time, 1.0);
        float alpha = froth.a * visible * foamLife;
        result.rgb = mix(result.rgb, froth.rgb * result.a, alpha);
    }

    // Detached droplets accompany the retreat into each corner.
    if (!opening) {
        vec2 local = min(uv, 1.0 - uv) * aspect;
        float travel = smoothstep(0.48, 0.98, t);
        float life = smoothstep(0.48, 0.64, t) * (1.0 - smoothstep(0.88, 1.0, t));
        for (int i = 0; i < 4; ++i) {
            vec2 random = surf_hash(vec2(float(i) + seed, 7.0));
            vec2 start = vec2(0.055) + random * min(aspect * 0.22, vec2(0.22));
            vec2 centre = mix(start, vec2(0.008) + random * 0.025, travel);
            float radius = (0.007 + random.x * 0.007) * (1.0 - travel * 0.55);
            float d = length(local - centre);
            float mask = (1.0 - smoothstep(radius, radius + aa, d)) * life;
            float alpha = mask * source.a;
            vec3 bead = mix(vec3(0.06, 0.42, 0.48), vec3(0.88, 0.97, 0.94),
                1.0 - smoothstep(0.0, radius, d));
            result = vec4(bead * alpha, alpha) + result * (1.0 - alpha);
        }
    }
    if (opening) result = mix(result, umbriel_sample(uv), smoothstep(0.88, 1.0, t));
    else result = mix(umbriel_sample(uv), result, smoothstep(0.0, 0.05, t));
    return result;
}
