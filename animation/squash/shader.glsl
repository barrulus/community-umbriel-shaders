vec4 animation(vec2 uv) {
    float p = umbriel_clamped_progress;
    float pulse = 16.0 * p * p * (1.0 - p) * (1.0 - p);
    vec2 scale = vec2(1.0 - 0.02 * pulse, 1.0 - 0.045 * pulse);
    return umbriel_sample((uv - 0.5) / scale + 0.5);
}
