// Adapted from shaders/window/prairie-wind.glsl

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
#define umbriel_size migration_buffer_size()
// Custom shader by Barrulus.
// Descending smoothstep edges are undefined in GLSL; preserve descending-edge falloff explicitly.
float smoothstep_any_order(float a, float b, float x) {
    return a > b ? 1.0 - smoothstep(b, a, x) : smoothstep(a, b, x);
}

float hash(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

float vnoise(vec2 p){
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p){
    float v   = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 4; i++){
        v  += amp * vnoise(p);
        p   = p * 2.03 + vec2(1.7, 9.2);
        amp *= 0.5;
    }
    return v;
}

// prairie palette: sage green through wheat gold to pale straw
vec3 pal(float x){
    vec3 col = mix(theme_color(vec3(0.28, 0.38, 0.20), 0.25), theme_color(vec3(0.78, 0.64, 0.28), 0.5), smoothstep_any_order(0.15, 0.55, x));
    return mix(col, theme_color(vec3(0.93, 0.88, 0.66), 0.5), smoothstep_any_order(0.60, 0.92, x));
}

vec4 postprocess(vec3 c){
    vec4  s  = tex2D_screen(c.xy);
    float ar = umbriel_size.x / max(umbriel_size.y, 1.0);
    float t  = umbriel_time;

    const float SWEEP    = 0.28;
    const float STRENGTH = 0.35;
    const float SHEEN    = 0.12;
    const float SHADE    = 0.07;
    const float SCALE    = 1.0;
    const float WANDER   = 1.4;
    const vec2  WIND     = vec2(0.966, 0.259);     // ~15 degrees downhill

    vec2  a    = vec2(c.x * ar, c.y);
    float gate = smoothstep_any_order(0.0, 0.25, s.a);       // respect rounded corners

    // the wind wanders: local direction strays from the mean, in space and slowly in time
    vec2  perp0 = vec2(-WIND.y, WIND.x);
    float wob   = ((fbm(a * 0.9 + vec2(t * 0.09, 0.0)) - 0.5) * WANDER + 0.25 * sin(t * 0.40));
    vec2  wdir  = normalize(WIND + perp0 * wob);
    vec2  wperp = vec2(-wdir.y, wdir.x);
    float u = dot(a, wdir);
    float v = dot(a, wperp);

    // gust field: advects along the (curving) wind, then gets warped again so the fronts
    // arrive bent and broken instead of as straight bands
    vec2 gp = vec2(u * 1.4 * SCALE - t * SWEEP * 2.2, v * 1.9 * SCALE);
    gp += (vec2(fbm(gp * 0.9 + 3.7), fbm(gp * 0.9 + 8.1)) - 0.5) * 0.9;
    float g  = fbm(gp);
    float g2 = fbm(gp + vec2(0.14, 0.0));          // one step upwind -> leading-edge detector

    // the whole wind surges and slackens...
    float surge = 0.70 + 0.30 * vnoise(vec2(t * 0.35, 3.3));
    float gust  = smoothstep_any_order(0.32, 0.70, g) * surge;
    // ...and patchy cat's-paw bursts flare up and die away on their own
    float paw   = fbm(a * 2.4 * SCALE + vec2(-t * SWEEP * 1.2, t * 0.10));
    float burst = smoothstep_any_order(0.50, 0.76, paw) * (0.55 + 0.45 * sin(t * 2.8 + paw * 12.0));
    gust = clamp(gust + burst * 0.7, 0.0, 1.0);

    // fine fast ripple riding wherever the wind works: the susurration
    float rip = (vnoise(vec2(u * 9.0 - t * SWEEP * 7.0, v * 14.0)) - 0.5) * gust;

    // the colour field the wind pushes around: advects downwind, surges ahead where a
    // front passes, eddies with the ripple — content underneath is never resampled
    float push = t * SWEEP * 1.6 + gust * 0.35 + rip * 0.15;
    float f    = fbm(vec2((u - push) * 2.2, v * 3.6 - t * 0.22));
    vec3  wc   = pal(clamp(f * 1.5 - 0.15, 0.0, 1.0));

    // the colour only shows where the wind is working; calm patches stay clear
    float amt = smoothstep_any_order(0.10, 0.65, gust) * STRENGTH * gate;
    vec3  rgb = mix(s.rgb, wc, amt);

    // pale flash where a front's leading edge catches the light...
    float front = clamp((g - g2) * 3.0, 0.0, 1.0) * gust;
    rgb += theme_color(vec3(0.90, 0.86, 0.68), 0.5) * front * SHEEN * s.a * gate;
    // ...and a slightly darker settle in the flattened trough behind it
    rgb *= 1.0 - SHADE * gust * (1.0 - front) * gate;
    // the ripple glitters like dry straw catching the light
    rgb += theme_color(vec3(0.88, 0.80, 0.52), 0.5) * max(rip, 0.0) * 0.12 * s.a * gate;

    return vec4(rgb, s.a);                         // s.a: keep rounded corners clean
}

vec4 window(vec2 uv) { return postprocess(vec3(uv, 0.0)); }
