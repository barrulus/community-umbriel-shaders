// Adapted from shaders/animations/water-conjure.glsl
// Side-view water conjuration. Use the same shader for open (+1) and close (-1).
// A drop lands, a column rises, and a foamy frame fills inward. On close the
// liquid window falls into a puddle. Suggested duration: 2000-2450 ms, linear.
// The foamy rim surrounds the forming silhouette inside the target canvas;
// it recedes as the finished window reaches its exact, unmodified bounds.

float conjure_hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float conjure_noise(vec2 p) {
    vec2 cell = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(conjure_hash(cell), conjure_hash(cell + vec2(1.0, 0.0)), f.x),
        mix(conjure_hash(cell + vec2(0.0, 1.0)), conjure_hash(cell + 1.0), f.x), f.y);
}

float conjure_ellipse(vec2 p, vec2 radii) {
    return (length(p / max(radii, vec2(0.001))) - 1.0) * min(radii.x, radii.y);
}

float conjure_box(vec2 p, vec2 halfSize, float rounding) {
    vec2 q = abs(p) - halfSize + rounding;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - rounding;
}

vec4 animation(vec2 uv) {
    float t = clamp(umbriel_linear_progress, 0.0, 1.0);
    bool opening = umbriel_direction > 0.0;
    if (t <= 0.0) return opening ? vec4(0.0) : umbriel_sample(uv);
    if (t >= 1.0) return opening ? umbriel_sample(uv) : vec4(0.0);

    vec2 size = max(umbriel_size, vec2(1.0));
    float unit = min(size.x, size.y);
    vec2 extent = size / unit;
    // y goes upward from the bottom of the window: gravity always points down.
    vec2 p = vec2((uv.x - 0.5) * extent.x, (1.0 - uv.y) * extent.y);
    float aa = 1.2 / unit;
    float seed = umbriel_random_seed.x * 6.2831853;
    float ground = 0.038;
    float noise = conjure_noise(p * 34.0 + vec2(seed, -t * 7.0));
    float detail = conjure_noise(p * 91.0 + vec2(t * 4.0, seed));
    float waterDistance = 10.0;
    float frameDistance = 10.0;
    float holeDistance = -10.0;
    float sheetMask = 0.0;
    float waterOpacity = 1.0;
    float material = 0.0;
    float foamAmount = 0.0;
    vec2 sampleUV = uv;

    float impactTime = opening ? 0.205 : 0.61;
    float splashAge = clamp((t - impactTime) / (opening ? 0.30 : 0.35), 0.0, 1.0);
    float splashVisible = smoothstep(0.0, 0.05, splashAge)
        * (1.0 - smoothstep(0.65, 1.0, splashAge));
    float poolLife = opening ? smoothstep(0.18, 0.25, t) * (1.0 - smoothstep(0.63, 0.86, t))
        : smoothstep(0.36, 0.65, t) * (1.0 - smoothstep(0.81, 1.0, t));
    float poolSpread = opening ? smoothstep(0.18, 0.45, t) : smoothstep(0.43, 0.87, t);
    float poolWidth = mix(0.065, extent.x * 0.46, poolSpread);
    float poolDepth = mix(0.027, 0.020, poolSpread);
    float poolDistance = conjure_ellipse(p - vec2(0.0, ground), vec2(poolWidth, poolDepth));

    if (opening) {
        // Accelerating drop, with a tapered trailing tip, before the impact.
        float fall = clamp(t / 0.225, 0.0, 1.0);
        float dropY = mix(extent.y * 0.90, ground + 0.027, fall * fall);
        vec2 drop = p - vec2(0.015 * sin(seed) * fall, dropY);
        float taper = 1.0 - 0.48 * smoothstep(-0.01, 0.07, drop.y);
        float dropDistance = conjure_ellipse(drop, vec2(0.031 * taper, 0.041 + 0.022 * fall));
        if (t < 0.235) waterDistance = min(waterDistance, dropDistance);

        // The central jet rises out of the pool, its bulb fanning out overhead.
        float rise = smoothstep(0.25, 0.54, t);
        float top = mix(ground + 0.018, extent.y - 0.045, rise);
        float level = clamp((p.y - ground) / max(top - ground, 0.001), 0.0, 1.0);
        float fan = smoothstep(0.38, 0.57, t);
        float jetWidth = 0.018 + 0.018 * (1.0 - level)
            + fan * extent.x * 0.32 * pow(level, 5.0);
        jetWidth += 0.004 * sin(p.y * 31.0 - t * 32.0 + seed);
        float cap = top - 0.035 * pow(clamp(abs(p.x) / max(jetWidth, 0.001), 0.0, 1.0), 2.0);
        float jet = max(abs(p.x - 0.006 * sin(p.y * 14.0 + t * 18.0)) - jetWidth,
            max(ground - p.y, p.y - cap));
        float jetLife = smoothstep(0.23, 0.29, t) * (1.0 - smoothstep(0.53, 0.69, t));
        if (jetLife > 0.001) waterDistance = min(waterDistance, jet + (1.0 - jetLife) * 0.06);

        // Water travels up the outline, then advances from the edges to centre.
        float frameRise = smoothstep(0.37, 0.64, t);
        float settle = smoothstep(0.84, 1.0, t);
        float inset = 0.032 * (1.0 - settle);
        float frameTop = mix(ground + 0.04, extent.y - inset, frameRise);
        float bottom = mix(ground, 0.0, settle);
        vec2 halfSize = vec2(mix(0.09, extent.x * 0.5 - inset, smoothstep(0.36, 0.58, t)),
            max(0.015, (frameTop - bottom) * 0.5));
        vec2 q = p - vec2(0.0, (frameTop + bottom) * 0.5);
        float turbulence = (1.0 - settle) * 0.011;
        q.x += turbulence * sin(p.y * 23.0 - t * 18.0 + seed);
        q.y += turbulence * sin(p.x * 27.0 + t * 15.0);
        float rounding = min(0.045 * (1.0 - settle), min(halfSize.x, halfSize.y));
        frameDistance = conjure_box(q, halfSize, rounding);
        float fill = smoothstep(0.55, 0.89, t);
        vec2 holeSize = max(vec2(0.001), halfSize - vec2(0.027) - halfSize * fill);
        holeDistance = conjure_box(q, holeSize, min(0.035, min(holeSize.x, holeSize.y)));
        holeDistance += (noise - 0.5) * 0.021 * (1.0 - fill);
        float outer = 1.0 - smoothstep(-aa, aa, frameDistance);
        float hole = smoothstep(-aa, aa, holeDistance);
        hole = mix(hole, 1.0, smoothstep(0.96, 1.0, fill));
        sheetMask = outer * hole * smoothstep(0.39, 0.48, t);
        material = smoothstep(0.64, 0.98, t);
        foamAmount = smoothstep(0.39, 0.49, t) * (1.0 - smoothstep(0.82, 1.0, t));
        sampleUV += vec2(sin(p.y * 25.0 - t * 17.0), cos(p.x * 21.0 + t * 12.0))
            * 0.015 * (1.0 - material);
        waterOpacity = smoothstep(0.0, 0.035, t);
    } else {
        // The window liquefies, sags and accelerates downward into the pool.
        float melt = smoothstep(0.0, 0.26, t);
        float fall = smoothstep(0.12, 0.70, t);
        float top = mix(extent.y, ground + 0.025, fall * fall);
        float bottom = mix(0.0, ground, smoothstep(0.08, 0.40, t));
        float height = max(0.015, top - bottom);
        float level = clamp((p.y - bottom) / height, 0.0, 1.0);
        float narrowing = 1.0 - 0.50 * fall * pow(level, 0.6);
        float halfWidth = extent.x * 0.5 * narrowing;
        float wobble = melt * (1.0 - smoothstep(0.62, 0.74, t));
        vec2 q = p - vec2(0.0, bottom + height * 0.5);
        q.x += 0.013 * wobble * sin(p.y * 22.0 + t * 19.0 + seed);
        q.y += 0.020 * wobble * (sin(p.x * 17.0 + t * 13.0) + 0.45 * sin(p.x * 37.0 - t * 21.0));
        frameDistance = conjure_box(q, vec2(halfWidth, height * 0.5),
            min(0.055 * melt, height * 0.45));
        sheetMask = (1.0 - smoothstep(-aa, aa, frameDistance))
            * (1.0 - smoothstep(0.64, 0.75, t));
        sampleUV = vec2(p.x / max(halfWidth * 2.0, 0.01) + 0.5, 1.0 - level);
        sampleUV += vec2(sin(p.y * 25.0 - t * 18.0), cos(p.x * 24.0 + t * 16.0)) * 0.014 * wobble;
        material = 1.0 - smoothstep(0.0, 0.35, t);
        foamAmount = melt * (1.0 - smoothstep(0.57, 0.75, t));
        waterOpacity = 1.0 - smoothstep(0.82, 1.0, t);
    }

    // Short connected sheets peel outward from the impact before breaking up.
    float arcReach = extent.x * 0.31;
    float arcU = abs(p.x) / max(arcReach, 0.001);
    float arcTop = ground + 0.15 * 4.0 * arcU * (1.0 - arcU);
    float arcSlope = 0.60 * (1.0 - 2.0 * arcU) / max(arcReach, 0.001);
    float arcDistance = abs(p.y - arcTop) / sqrt(1.0 + arcSlope * arcSlope);
    arcDistance = max(arcDistance - 0.010 * (1.0 - clamp(arcU, 0.0, 1.0)),
        (arcU - min(splashAge * 2.8, 1.0)) * arcReach);
    float arcLife = splashVisible * (1.0 - smoothstep(0.25, 0.65, splashAge));
    if (arcLife > 0.001) waterDistance = min(waterDistance, arcDistance + (1.0 - arcLife) * 0.035);

    // Ballistic beads arc up from the impact and fall back down.
    for (int i = 0; i < 10; ++i) {
        float index = float(i);
        float random = conjure_hash(vec2(index, umbriel_random_seed.y));
        float side = mod(index, 2.0) * 2.0 - 1.0;
        float age = clamp(splashAge * 1.22 - random * 0.17, 0.0, 1.0);
        float x = side * (0.035 + age * extent.x * (0.20 + 0.22 * random));
        float y = ground + (0.18 + 0.18 * random) * 4.0 * age * (1.0 - age);
        vec2 delta = p - vec2(x, y);
        float bead = conjure_ellipse(delta, vec2(0.009 + 0.008 * random, 0.013 + 0.013 * random));
        if (splashVisible > 0.001) waterDistance = min(waterDistance, bead + (1.0 - splashVisible) * 0.045);
    }

    // Glossy water and small moving caustics; sampled alpha gates every layer.
    vec4 original = umbriel_sample(clamp(sampleUV, vec2(0.001), vec2(0.999)));
    vec4 liquidSource = umbriel_sample(clamp(vec2(uv.x, 0.72), vec2(0.04), vec2(0.96)));
    float boundary = min(abs(poolDistance), min(abs(waterDistance), abs(frameDistance)));
    float rim = exp(-boundary / 0.006);
    float threads = pow(0.5 + 0.5 * sin(p.x * 74.0 + noise * 9.0 + p.y * 6.0 - t * 14.0), 10.0);
    vec3 water = vec3(0.025, 0.22, 0.32) + vec3(0.045, 0.20, 0.25) * noise;
    water += vec3(0.22, 0.43, 0.48) * (rim * 0.75 + threads * 0.30);
    water = min(water, vec3(1.0));
    float poolMask = (1.0 - smoothstep(-aa, aa, poolDistance)) * poolLife;
    float fluidMask = max(poolMask, 1.0 - smoothstep(-aa, aa, waterDistance));
    vec4 fluid = vec4(water * liquidSource.a, liquidSource.a) * fluidMask * waterOpacity;
    vec4 sheetWater = vec4(water * original.a, original.a);
    vec4 sheet = mix(sheetWater, original, material) * sheetMask;
    vec4 result = sheet + fluid * (1.0 - sheet.a);

    // A broken, bubbly foam fringe just OUTSIDE the forming window outline.
    float foamWidth = 0.005 + 0.013 * noise;
    float foam = (1.0 - smoothstep(foamWidth, foamWidth + aa, frameDistance))
        * smoothstep(-0.004, 0.002, frameDistance);
    foam *= smoothstep(0.30, 0.65, detail) * foamAmount;
    vec4 froth = vec4(vec3(0.79, 0.94, 0.97) * liquidSource.a, liquidSource.a) * foam;
    result = froth + result * (1.0 - froth.a);

    // Settle continuously to exact source sampling, including rounded corners.
    if (opening) result = mix(result, umbriel_sample(uv), smoothstep(0.94, 1.0, t));
    else result = mix(umbriel_sample(uv), result, smoothstep(0.0, 0.055, t));
    return result;
}
