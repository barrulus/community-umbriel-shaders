// SPDX-FileCopyrightText: Simon Schneegans <code@simonschneegans.de>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// TV Glitch: ported from Burn-My-Windows (resources/shaders/tv-glitch.frag) to Umbriel.
// The original combines Burn-My-Windows' "TV" and "Glitch" effects; credit for that idea
// goes to Kurt Wilson (https://github.com/Kurtoid). hash12/hash22 are by David Hoskins
// (MIT, https://www.shadertoy.com/view/4djSRW) and simplex2D is by Inigo Quilez
// (MIT, https://www.shadertoy.com/view/Msf3WH), both as bundled in Burn-My-Windows.
//
// Use for windows_in and windows_out (also works for layers and scratchpad). The glitch
// runs on its own internal easing, so select curve = "linear".

// ------------------------------------------------------------------------------ tuning

// Tint of the interference, grain, scan lines and the final collapse, as straight RGB.
// Alpha (0-1) scales how strongly the tint is mixed in. Upstream default: rgb(100,160,255).
// With `palette = true` in effect.toml, accent_primary is used instead.
const vec4 GLITCH_COLOR = vec4(100.0 / 255.0, 160.0 / 255.0, 1.0, 1.0);

// Size of the noise bands; larger values give thinner, busier bands (useful 0.1-4).
const float GLITCH_SCALE = 1.0;

// Horizontal displacement and interference intensity (useful 0-4; 0 disables the glitch).
const float GLITCH_STRENGTH = 2.0;

// How far the noise pattern travels during one animation. Upstream multiplies the
// animation duration (0.75 s by default) by its speed setting (2.0 by default).
const float GLITCH_TIME_SPAN = 0.75 * 2.0;

const float BLUR_WIDTH = 0.01;  // Softness of the collapsing edges, in UV units.
const float TB_TIME    = 0.7;   // Share of the TV phase spent collapsing top/bottom.
const float LR_TIME    = 0.4;   // Share of the TV phase spent collapsing left/right.
const float LR_DELAY   = 0.6;   // Point in the TV phase where left/right collapse starts.
const float FF_TIME    = 0.1;   // Share of the TV phase for the final fade.
const float SCALING    = 0.5;   // Vertical squash of the window at full collapse.

// ----------------------------------------------------------------------------- helpers

float tvg_hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 tvg_hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

float tvg_simplex2D(vec2 p) {
    const float K1 = 0.366025404;  // (sqrt(3)-1)/2
    const float K2 = 0.211324865;  // (3-sqrt(3))/6
    vec2 i  = floor(p + (p.x + p.y) * K1);
    vec2 a  = p - i + (i.x + i.y) * K2;
    float m = step(a.y, a.x);
    vec2 o  = vec2(m, 1.0 - m);
    vec2 b  = a - o + K2;
    vec2 c  = a - 1.0 + 2.0 * K2;
    vec3 h  = max(0.5 - vec3(dot(a, a), dot(b, b), dot(c, c)), 0.0);
    vec3 n  = h * h * h * h *
             vec3(dot(a, -1.0 + 2.0 * tvg_hash22(i)), dot(b, -1.0 + 2.0 * tvg_hash22(i + o)),
                  dot(c, -1.0 + 2.0 * tvg_hash22(i + 1.0)));
    return 0.5 + 0.5 * dot(n, vec3(70.0));
}

float tvg_ease_out_quad(float x) { return -x * (x - 2.0); }
float tvg_ease_in_quad(float x) { return x * x; }

// Umbriel samples are premultiplied; the upstream maths works on straight alpha.
vec4 tvg_sample_straight(vec2 uv) {
    vec4 c = umbriel_sample(uv);
    if (c.a > 0.0) c.rgb /= c.a;
    return c;
}

// ------------------------------------------------------------------------- entry point

vec4 animation(vec2 uv) {
    bool opening = umbriel_direction > 0.0;
    float p = umbriel_clamped_progress;

    vec4 tint = GLITCH_COLOR;
    if (umbriel_palette_count > 0) tint = vec4(umbriel_palette_at(0.0).rgb, GLITCH_COLOR.a);

    // The TV collapse occupies the first half of an opening and the second half of a
    // closing, exactly as upstream.
    float tvProgress = clamp(p * 2.0 - (opening ? 0.0 : 1.0), 0.0, 1.0);
    tvProgress = opening ? 1.0 - tvg_ease_out_quad(tvProgress) : tvg_ease_out_quad(tvProgress);

    // Squash the window vertically.
    float scale = 1.0 / mix(1.0, SCALING, tvProgress) - 1.0;
    vec2 coords = uv;
    coords.y    = coords.y * (scale + 1.0) - scale * 0.5;

    // Glitch part. Distances are in logical pixels so the look is scale-independent.
    float progress = tvg_ease_in_quad(opening ? 1.0 - p : p);
    float time     = progress * GLITCH_TIME_SPAN;
    float strength = GLITCH_STRENGTH * progress;
    float displace = 1000.0 * strength / umbriel_size.x;
    float yPos     = GLITCH_SCALE * umbriel_size.y * (coords.y + umbriel_random_seed.x * 10.0);

    // Large noise waves plus some smaller ones.
    float noise = clamp(tvg_simplex2D(vec2(time, yPos * 0.002)) - 0.5, 0.0, 1.0);
    noise += (tvg_simplex2D(vec2(time * 10.0, yPos * 0.05)) - 0.5) * 0.15;

    // Displace every line horizontally.
    float xPos  = clamp(coords.x - displace * noise * noise, 0.0, 1.0);
    vec4 color  = tvg_sample_straight(vec2(xPos, coords.y));

    // Random interference lines.
    vec3 interference = tint.rgb * tvg_hash12(vec2(yPos * time));
    color.rgb = mix(color.rgb, interference, tint.a * noise * min(strength, 1.0));

    // Grain.
    vec3 grain = tint.rgb * tvg_simplex2D(umbriel_size * coords + vec2(time * 100.0));
    color.rgb  = mix(color.rgb, grain, tint.a * 0.2 * min(strength, 1.0));

    // Subtle line pattern every four logical pixels. Upstream leaves this at full weight
    // even when strength is zero; fading it in over the first few percent of the glitch
    // makes the opening end on (and the closing start from) the untouched window.
    if (floor(mod(yPos * 0.25, 2.0)) == 0.0) {
        float lineGate = min(strength * 10.0, 1.0);
        color.rgb = mix(color.rgb, tint.rgb, tint.a * 0.15 * noise * lineGate);
    }

    // Offset green and blue channels.
    float offset = 0.1 * noise * displace;
    color.g = mix(color.g, tvg_sample_straight(vec2(xPos + offset, coords.y)).g, 0.25);
    color.b = mix(color.b, tvg_sample_straight(vec2(xPos - offset, coords.y)).b, 0.25);

    // TV collapse masks, each in [0, 1] during its stage.
    float tbProg = smoothstep(0.0, 1.0, clamp(tvProgress / TB_TIME, 0.0, 1.0));
    float lrProg = smoothstep(0.0, 1.0, clamp((tvProgress - LR_DELAY) / LR_TIME, 0.0, 1.0));
    float ffProg = smoothstep(0.0, 1.0, clamp((tvProgress - 1.0 + FF_TIME) / FF_TIME, 0.0, 1.0));

    float tb = coords.y * 2.0;  // 0 at top/bottom, 1 at the centre line
    tb       = tb < 1.0 ? tb : 2.0 - tb;
    float lr = coords.x * 2.0;  // 0 at left/right, 1 at the centre column
    lr       = lr < 1.0 ? lr : 2.0 - lr;

    float tbMask = 1.0 - smoothstep(0.0, 1.0, clamp((tbProg - tb) / BLUR_WIDTH, 0.0, 1.0));
    float lrMask = 1.0 - smoothstep(0.0, 1.0, clamp((lrProg - lr) / BLUR_WIDTH, 0.0, 1.0));
    float ffMask = 1.0 - smoothstep(0.0, 1.0, ffProg);

    // Glow towards the tint as the picture collapses.
    color.rgb = mix(color.rgb, tint.rgb * color.a, tint.a * smoothstep(0.0, 1.0, tvProgress));

    float alpha = color.a * tbMask * lrMask * ffMask;
    return vec4(color.rgb * alpha, alpha);
}
