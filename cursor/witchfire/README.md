# Witchfire

A long green witchfire ribbon follows a time-weighted Catmull–Rom curve. Thin flame wisps peel away from its bends, and orange embers drift behind it. Twelve subdivisions per segment smooth fast swirls instead of joining retained samples with straight chords.

![Headless compositor preview](preview.png)

This is an isolated Umbriel capture over synthetic content. A still image does
not demonstrate motion, output transforms or performance.

## Use

Save this directory under `~/.config/umbriel/shaders/community/cursor/witchfire/`.
Merge [config.toml](config.toml) into your configuration, appending include paths
and merging existing tables. Including a preset registers it; selection enables
it. The preset name is `after-dark.witchfire`.

## Configuration options

INTENSITY = 0.8 (0–1), TRAIL_LIFE = 1.25 seconds (0.5–1.5), FLAME_WIDTH = 10 logical pixels (4–14). Radius 128 pads the retained path.

## Compatibility and cost

Requires Umbriel’s preset-effects API. One source sample; up to 63 curve segments with 12 subdivisions each and conservative distance rejection. Uses pointer-history ages, ignores stationary samples and jumps over 800 pixels, and has no feedback buffers. Requires the pointer-history API.
Hardware performance has not been benchmarked. See the [validation record](../../VALIDATION.md#halloween-presets-2026-10-09).

## Attribution

Curve interpolation adapted from Comet and Noctalia’s bundled trail shader. Licenses: [Barrulus MIT](../../LICENSES/Barrulus-MIT.txt) and [Noctalia MIT](../../LICENSES/Noctalia-MIT.txt).
