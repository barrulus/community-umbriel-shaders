// Minimal opening effect for Umbriel's animation.windows_in event.
// It fades and gently scales the target from its center.
vec4 animation(vec2 uv) {
    float progress = umbriel_clamped_progress;
    float scale = mix(0.96, 1.0, progress);
    vec4 color = umbriel_sample((uv - 0.5) / scale + 0.5);
    return color * progress;
}
