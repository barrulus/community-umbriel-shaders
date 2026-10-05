// SPDX-License-Identifier: MIT
export const effects = [
  ['shattered-glass', 'Shattered Glass', 'Unequal polygonal shards break loose at different times, spinning and falling independently. Opening reassembles them.'],
  ['wet-paint', 'Wet Paint', 'Long, uneven paint streams pour down to form the window and melt down to remove it.'],
  ['flame-grilled', 'Flame Grilled', 'Tall, rolling flames sweep down to reveal the window and burn upward to consume it.'],
  ['glitch', 'Glitch', 'Digital blocks, displaced bands, and separated colors vibrate into and out of existence.'],
  ['cells', 'Cells', 'Pentagonal outlines grow from the centre, fill or empty, and retreat to the centre.'],
  ['void', 'Void', 'A broad violet vortex spirals into a black core, releasing the window or drawing it back in.'],
  ['old-tv', 'Old TV', 'The picture collapses to a phosphor line, then lingers as a bright central blink. Opening reverses the shutdown.'],
  ['vhs', 'VHS', 'Rolling tracking errors stretch the image with analog noise and color bleed.'],
  ['magic', 'Magic', 'A violet puff and golden sparkles reveal or dissolve the window.'],
  ['triangle-flaps', 'Triangle Flaps', 'Equilateral up/down triangles appear haphazardly, unfolding downward or falling away under gravity.'],
];
const $ = id => document.getElementById(id);
const canvas = $('screen');
const gl = canvas.getContext('webgl', {alpha: true, premultipliedAlpha: true, preserveDrawingBuffer: true, antialias: false});
if (!gl) throw new Error('WebGL 1 is required for this preview.');
const header = `precision highp float;
#define sin(x) sin(mod((x), 6.283185307179586))
#define cos(x) cos(mod((x), 6.283185307179586))
varying vec2 v_texcoord;
uniform sampler2D umbriel_texture;
uniform vec2 umbriel_size;
uniform float umbriel_progress;
uniform float umbriel_linear_progress;
uniform float umbriel_direction;
uniform vec4 umbriel_random_seed;
uniform int umbriel_palette_count;
vec4 umbriel_palette_at(float t) {
  if (umbriel_palette_count <= 0) return vec4(0.0);
  float phase = fract(t) * 4.0;
  vec4 primary = vec4(0.796, 0.651, 0.969, 1.0);
  vec4 secondary = vec4(0.537, 0.706, 0.980, 1.0);
  vec4 warning = vec4(0.976, 0.886, 0.686, 1.0);
  vec4 error = vec4(0.953, 0.545, 0.659, 1.0);
  if (phase < 1.0) return mix(primary, secondary, phase);
  if (phase < 2.0) return mix(secondary, warning, phase - 1.0);
  if (phase < 3.0) return mix(warning, error, phase - 2.0);
  return mix(error, primary, phase - 3.0);
}
#define umbriel_clamped_progress clamp(umbriel_progress, 0.0, 1.0)
vec4 umbriel_sample(vec2 uv) {
  if (any(lessThan(uv, vec2(0.0))) || any(greaterThan(uv, vec2(1.0)))) return vec4(0.0);
  return texture2D(umbriel_texture, uv);
}
`;
function compile(type, source) {
  const shader = gl.createShader(type);
  gl.shaderSource(shader, source);
  gl.compileShader(shader);
  if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
    const message = gl.getShaderInfoLog(shader);
    gl.deleteShader(shader);
    throw new Error(message);
  }
  return shader;
}
function program(source) {
  const vertex = compile(gl.VERTEX_SHADER, `attribute vec2 position; varying vec2 v_texcoord;
    void main() { v_texcoord = position * vec2(0.5, -0.5) + 0.5; gl_Position = vec4(position, 0.0, 1.0); }`);
  const fragment = compile(gl.FRAGMENT_SHADER, header + source + '\nvoid main() { gl_FragColor = animation(v_texcoord); }');
  const result = gl.createProgram();
  gl.attachShader(result, vertex);
  gl.attachShader(result, fragment);
  gl.bindAttribLocation(result, 0, 'position');
  gl.linkProgram(result);
  gl.deleteShader(vertex);
  gl.deleteShader(fragment);
  if (!gl.getProgramParameter(result, gl.LINK_STATUS)) throw new Error(gl.getProgramInfoLog(result));
  return result;
}
const buffer = gl.createBuffer();
gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1,-1, 1,-1, -1,1, -1,1, 1,-1, 1,1]), gl.STATIC_DRAW);
gl.enableVertexAttribArray(0);
gl.vertexAttribPointer(0, 2, gl.FLOAT, false, 0, 0);
const texture = gl.createTexture();
gl.bindTexture(gl.TEXTURE_2D, texture);
gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);

function setTexture(width = canvas.width, height = canvas.height, translucent = false, empty = false) {
  const sample = document.createElement('canvas');
  sample.width = width;
  sample.height = height;
  const c = sample.getContext('2d');
  if (!empty) {
    c.scale(width / 640, height / 400);
    c.globalAlpha = translucent ? 0.58 : 1;
    c.beginPath(); c.roundRect(8, 8, 624, 384, 16); c.clip();
    c.fillStyle = '#edf1f8'; c.fillRect(0, 0, 640, 400);
    c.fillStyle = '#26324b'; c.fillRect(0, 0, 640, 52);
    ['#ff867b', '#ffd377', '#81d9ba'].forEach((color, i) => {
      c.fillStyle = color; c.beginPath(); c.arc(30 + i * 21, 30, 5, 0, Math.PI * 2); c.fill();
    });
    c.globalAlpha = 1;
    c.fillStyle = '#e1e9fa'; c.font = '13px sans-serif'; c.fillText('Observatory / Field notes', 235, 35);
    c.fillStyle = '#24324e'; c.font = 'bold 28px sans-serif'; c.fillText('An ordinary window.', 38, 103);
    c.fillStyle = '#596783'; c.font = '15px sans-serif'; c.fillText('A little motion makes it extraordinary.', 38, 130);
    const gradient = c.createLinearGradient(38, 157, 375, 355);
    gradient.addColorStop(0, '#28527e'); gradient.addColorStop(0.52, '#9671b6'); gradient.addColorStop(1, '#f3b991');
    c.fillStyle = gradient; c.fillRect(38, 157, 338, 197);
    c.fillStyle = '#ffe4af'; c.beginPath(); c.arc(279, 207, 25, 0, Math.PI * 2); c.fill();
    c.fillStyle = '#203855'; c.beginPath(); c.moveTo(38, 354); c.lineTo(113, 234); c.lineTo(171, 300); c.lineTo(228, 253); c.lineTo(376, 354); c.fill();
    c.fillStyle = '#516b82'; c.beginPath(); c.moveTo(38, 354); c.lineTo(149, 295); c.lineTo(212, 330); c.lineTo(294, 278); c.lineTo(376, 354); c.fill();
    c.fillStyle = '#3d5474'; c.font = 'bold 14px sans-serif'; c.fillText('AFTER THE RAIN', 400, 177);
    c.fillStyle = '#95a4bb'; [203, 219, 235, 264, 280, 296].forEach((y, i) => c.fillRect(400, y, i % 3 === 2 ? 116 : 185, 6));
    c.fillStyle = '#578cad'; c.fillRect(400, 323, 92, 31);
    c.fillStyle = '#ffffff'; c.font = '13px sans-serif'; c.fillText('Explore', 423, 344);
    // A transparent cutout exercises sampled alpha independently of the border.
    if (translucent) { c.clearRect(530, 310, 60, 40); }
  }
  gl.pixelStorei(gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, true);
  gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, sample);
}
const programs = new Map();
const timings = new Map();
for (const [id, name] of effects) $('effect').add(new Option(name, id));
let current, playing = false, began = 0, last = 0;
const seed = [0.31, 0.73, 0.19, 0.61];
function draw(p, progress, direction, size = [canvas.width, canvas.height], random = seed) {
  gl.useProgram(p);
  gl.viewport(0, 0, canvas.width, canvas.height);
  gl.uniform1i(gl.getUniformLocation(p, 'umbriel_texture'), 0);
  gl.uniform1i(gl.getUniformLocation(p, 'umbriel_palette_count'), $('palette').checked ? 4 : 0);
  gl.uniform2fv(gl.getUniformLocation(p, 'umbriel_size'), size);
  gl.uniform1f(gl.getUniformLocation(p, 'umbriel_progress'), progress);
  gl.uniform1f(gl.getUniformLocation(p, 'umbriel_linear_progress'), progress);
  gl.uniform1f(gl.getUniformLocation(p, 'umbriel_direction'), direction);
  gl.uniform4fv(gl.getUniformLocation(p, 'umbriel_random_seed'), random);
  gl.drawArrays(gl.TRIANGLES, 0, 6);
}
function render(progress) {
  last = progress;
  draw(current, progress, Number($('direction').value));
  $('progress').value = progress;
  $('position').value = `${Math.round(progress * 100)}%`;
}
function play() { playing = true; began = performance.now(); $('play').textContent = 'Pause'; }
function pause() { playing = false; $('play').textContent = 'Replay'; }
function updateTimingLabel() {
  const duration = timings.get($('effect').value)?.[Number($('direction').value)];
  $('duration').options[0].textContent = duration ? `Effect timing (${duration} ms)` : 'Effect timing';
}
async function select() {
  const id = $('effect').value;
  if (!timings.has(id)) {
    const response = await fetch(`../animation/${id}/config.toml`);
    if (!response.ok) throw new Error(`Cannot load ${id} timing: ${response.status}`);
    const config = await response.text();
    const durations = {};
    for (const [event, direction] of [['windows_in', 1], ['windows_out', -1]]) {
      const section = config.split(`[animation.${event}]`)[1]?.split('[')[0];
      const duration = section?.match(/duration_ms\s*=\s*(\d+)/)?.[1];
      if (!duration) throw new Error(`Missing ${event} duration for ${id}`);
      durations[direction] = Number(duration);
    }
    timings.set(id, durations);
  }
  if (!programs.has(id)) {
    const response = await fetch(`../animation/${id}/shader.glsl`);
    if (!response.ok) throw new Error(`Cannot load ${id}: ${response.status}`);
    programs.set(id, program(await response.text()));
  }
  if ($('effect').value !== id) return;
  current = programs.get(id);
  updateTimingLabel();
  $('description').textContent = effects.find(e => e[0] === id)[2];
  $('source').href = `../animation/${id}/shader.glsl`;
  render(0); play();
}
function resize() {
  [canvas.width, canvas.height] = $('shape').value.split(',').map(Number);
  setTexture(canvas.width, canvas.height, $('translucent').checked);
  if (current) render(last);
}
$('effect').onchange = () => select().catch(showError);
$('direction').onchange = () => { updateTimingLabel(); play(); };
$('duration').onchange = play;
$('shape').onchange = resize;
$('translucent').onchange = resize;
$('palette').onchange = () => { if (current) render(last); };
$('play').onclick = () => playing ? pause() : play();
$('progress').oninput = () => { pause(); render(Number($('progress').value)); };
function frame(now) {
  if (playing && current) {
    const elapsed = now - began;
    const duration = $('duration').value === 'preset'
      ? timings.get($('effect').value)?.[Number($('direction').value)] ?? 750
      : Number($('duration').value);
    render(Math.min(1, elapsed / duration));
    if (elapsed > duration + 500) {
      if ($('loop').checked) began = now;
      else pause();
    }
  }
  requestAnimationFrame(frame);
}
function showError(error) { $('error').textContent = error.message; pause(); }

// Used by the browser validation runner and for reproducible preview captures.
window.preview = {
  effects,
  async loadAll() {
    for (const [id] of effects) {
      if (!programs.has(id)) {
        const response = await fetch(`../animation/${id}/shader.glsl`);
        if (!response.ok) throw new Error(`Cannot load ${id}`);
        programs.set(id, program(await response.text()));
      }
    }
    return programs.size;
  },
  capture(id, progress, direction = 1) {
    pause(); draw(programs.get(id), progress, direction);
    return canvas.toDataURL('image/png');
  },
  validate() {
    pause();
    const reference = program('vec4 animation(vec2 uv) { return umbriel_sample(uv); }');
    const reports = [];
    const read = () => {
      const pixels = new Uint8Array(canvas.width * canvas.height * 4);
      gl.readPixels(0, 0, canvas.width, canvas.height, gl.RGBA, gl.UNSIGNED_BYTE, pixels);
      if (gl.getError() !== gl.NO_ERROR) throw new Error('WebGL draw/read error');
      return pixels;
    };
    canvas.width = 128; canvas.height = 96;
    try {
      for (const [id, p] of programs) {
        let frames = 0;
        for (const size of [[640, 400], [320, 720], [64, 64], [1920, 160]]) {
          for (const translucent of [false, true]) {
            setTexture(128, 96, translucent);
            draw(reference, 1, 1); const expected = read();
            for (const random of [seed, [0, 0, 0, 0], [0.99, 0.01, 0.5, 0.9]]) {
              for (const direction of [1, -1]) {
                for (const t of [0, 0.001, 0.05, 0.15, 0.25, 0.4, 0.5, 0.65, 0.8, 0.95, 0.999, 1]) {
                  draw(p, t, direction, size, random); const pixels = read(); frames++;
                  const visible = direction > 0 ? t === 1 : t === 0;
                  for (let i = 0; i < pixels.length; i += 4) {
                    const alpha = pixels[i + 3];
                    if (pixels[i] > alpha + 1 || pixels[i + 1] > alpha + 1 || pixels[i + 2] > alpha + 1)
                      throw new Error(`${id}: invalid premultiplied pixel at ${t}, direction ${direction}`);
                  }
                  if (t === 0 || t === 1) {
                    if (pixels.some((v, i) => Math.abs(v - (visible ? expected[i] : 0)) > 1))
                      throw new Error(`${id}: wrong endpoint at ${t}, direction ${direction}`);
                  }
                }
              }
            }
          }
        }
        reports.push({effect: id, frames, result: 'pass'});
      }
    } finally { gl.deleteProgram(reference); resize(); render(last); }
    return reports;
  },
};
resize();
window.previewReady = select().catch(error => { showError(error); throw error; });
requestAnimationFrame(frame);
