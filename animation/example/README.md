# Example animation shader

A minimal opening effect for Umbriel's `animation.windows_in` event. It fades a
target in while scaling it from 96% to its normal size.

## Compatibility

- **Target:** `animation.windows_in`
- **Shader API:** Umbriel custom animation shaders, GLSL ES 1.00
- **Feedback:** none

The effect has no special GPU requirements. Its first frame is transparent and
its final frame is the unmodified target, so it agrees with Umbriel's normal
open state.

## Use

When this repository is cloned to `~/.config/umbriel/shaders/community`, merge
this directory's [`config.toml`](config.toml) into
`~/.config/umbriel/config.toml`. The configured relative path resolves to this
shader.
