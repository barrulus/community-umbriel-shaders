# Paired window transition preview

From the repository root, start a local static server:

```sh
python3 -m http.server 8765 --bind 127.0.0.1
```

Open [the preview](http://127.0.0.1:8765/preview/) in a browser with WebGL 1.
No installation or build step is needed. Select an effect, direction, and window
shape. Replay, slow the animation, or scrub through it; the translucent sample
also contains a transparent cutout. Stop the server with Ctrl+C when finished.

The default **Effect timing** reads the selected effect's `config.toml`, including
its separate opening and closing durations. The other duration options override
that timing for inspection.

The page loads the actual self-contained `animation/*/shader.glsl` files. Its
wrapper reproduces the animation uniforms and premultiplied texture sampling
for a synthetic window. It does not reproduce compositor capture, output
rotation, HDR, scaling, or interrupted transitions. Nothing changes your
Umbriel configuration.

To repeat the WebGL compilation, endpoint, and premultiplied-alpha checks,
run this in the browser developer console:

```js
await window.preview.loadAll();
console.table(window.preview.validate());
```

This checks 576 frames per effect across both directions, four logical window
shapes, three seeds, and opaque/translucent inputs. Each report must say `pass`;
failure throws an error identifying the effect. Validation pauses playback.
Full compositor validation is described in [VALIDATION.md](../VALIDATION.md).

The preview and its sample illustration are original code by Barrulus with
Codex assistance, licensed under [MIT](../LICENSES/Barrulus-MIT.txt).

The **Theme palette** checkbox uses the four example `[colors]` values from the
main README. Clear it to see the original colours used in the static previews.
