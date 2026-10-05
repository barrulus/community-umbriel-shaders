// Adapted from shaders/rings/pink-ribbon.glsl

// Theme colours affect artwork only; palette = false restores the original RGB.
// Keep the original shade and soften highlights without changing effect opacity.
vec3 theme_color(vec3 original, float position) {
    if (umbriel_palette_count <= 0) return original;
    float value = max(original.r, max(original.g, original.b));
    float white = min(original.r, min(original.g, original.b)) / max(value, 0.0001);
    return value * mix(umbriel_palette_at(position).rgb, vec3(1.0), white * 0.75);
}

#define ring_padding 24.0
#define ring_size (umbriel_border_hole.zw * umbriel_size)
#define ring_width max((1.0 - umbriel_border_hole.w) * umbriel_size.y * 0.5 - ring_padding, 1.0)
#define ring_radius umbriel_border_radius
float ring_distance(vec2 coords) { return umbriel_border_distance(coords / umbriel_size + umbriel_border_hole.xy); }
const float RIBBON_PI = 3.14159265359;
const float RIBBON_INSET = 30.0;

float ribbon_scale() { return min(1.0, min(ring_size.x, ring_size.y) / 180.0); }
float ribbon_margin() { return 0.0; }
vec2 ribbon_track_size() { return ring_size - 2.0 * ribbon_margin(); }
float ribbon_radius() {
    vec2 track = ribbon_track_size();
    return min(14.0 * ribbon_scale(), min(track.x, track.y) * 0.25);
}
float ribbon_perimeter() {
    vec2 track = ribbon_track_size();
    return 2.0 * (track.x + track.y) - (8.0 - 2.0 * RIBBON_PI) * ribbon_radius();
}

vec4 ribbon_frame(float along) {
    vec2 track = ribbon_track_size();
    vec2 origin = vec2(ribbon_margin());
    float r = ribbon_radius();
    float s = mod(along, ribbon_perimeter());
    for (int side = 0; side < 4; side++) {
        float line;
        vec2 start, tangent, center;
        if (side == 0) {
            line = track.x - 2.0 * r;
            start = vec2(r, 0.0); tangent = vec2(1.0, 0.0); center = vec2(track.x - r, r);
        } else if (side == 1) {
            line = track.y - 2.0 * r;
            start = vec2(track.x, r); tangent = vec2(0.0, 1.0); center = track - r;
        } else if (side == 2) {
            line = track.x - 2.0 * r;
            start = vec2(track.x - r, track.y); tangent = vec2(-1.0, 0.0); center = vec2(r, track.y - r);
        } else {
            line = track.y - 2.0 * r;
            start = vec2(0.0, track.y - r); tangent = vec2(0.0, -1.0); center = vec2(r);
        }
        if (s <= line) return vec4(origin + start + tangent * s, tangent);
        s -= line;
        float arc = RIBBON_PI * r * 0.5;
        if (s <= arc || side == 3) {
            float angle = (float(side) - 1.0) * RIBBON_PI * 0.5 + s / max(r, 0.001);
            return vec4(origin + center + r * vec2(cos(angle), sin(angle)), -sin(angle), cos(angle));
        }
        s -= arc;
    }
    return vec4(origin + vec2(r, 0.0), 1.0, 0.0);
}

vec2 ribbon_project(vec2 p) {
    vec2 track = ribbon_track_size(), origin = vec2(ribbon_margin());
    float r = ribbon_radius(), base = 0.0, best = 1.0e20;
    vec2 result = vec2(0.0);
    for (int side = 0; side < 4; side++) {
        vec4 frame;
        if (side == 0) frame = vec4(origin + vec2(r,0.0),1.0,0.0);
        else if (side == 1) frame = vec4(origin + vec2(track.x,r),0.0,1.0);
        else if (side == 2) frame = vec4(origin + vec2(track.x-r,track.y),-1.0,0.0);
        else frame = vec4(origin + vec2(0.0,track.y-r),0.0,-1.0);
        float line = (side == 0 || side == 2 ? track.x : track.y) - 2.0 * r;
        float t = clamp(dot(p - frame.xy, frame.zw), 0.0, line);
        vec2 delta = p - frame.xy - frame.zw * t;
        float d2 = dot(delta, delta);
        if (d2 < best) {
            best = d2;
            result = vec2(base + t, dot(delta, vec2(frame.w, -frame.z)));
        }
        base += line;
        vec2 center;
        if (side == 0) center = vec2(track.x - r, r);
        else if (side == 1) center = track - r;
        else if (side == 2) center = vec2(r, track.y - r);
        else center = vec2(r);
        delta = p - origin - center;
        float start = (float(side) - 1.0) * RIBBON_PI * 0.5;
        float angle = mod(atan(delta.y, delta.x) - start + RIBBON_PI, 2.0 * RIBBON_PI) - RIBBON_PI;
        angle = clamp(angle, 0.0, RIBBON_PI * 0.5);
        vec2 outward = vec2(cos(start + angle), sin(start + angle));
        vec2 diff = delta - r * outward;
        d2 = dot(diff, diff);
        if (d2 < best) {
            best = d2;
            result = vec2(base + angle * r, dot(diff, outward));
        }
        base += RIBBON_PI * r * 0.5;
    }
    return result;
}

vec4 ribbon_over(vec4 under, vec4 paint) { return paint + under * (1.0-paint.a); }
float ribbon_wave(float along, float perimeter) {
    float cycles = max(2.0,floor(perimeter/155.0));
    float phase = (along-umbriel_time*48.0)/perimeter * cycles * 2.0*RIBBON_PI;
    phase -= umbriel_time*0.65;
    return -3.5 + 7.5*sin(phase) + 2.0*sin(phase*2.0+0.7);
}
float ribbon_heart(vec2 p) {
    p.x=abs(p.x);
    if(p.x+p.y>1.0) return length(p-vec2(0.25,0.75))-0.35355339;
    vec2 a=p-vec2(0.0,1.0), b=p-0.5*max(p.x+p.y,0.0);
    return sqrt(min(dot(a,a),dot(b,b)))*sign(p.x-p.y);
}
vec4 ring_color(vec2 coords) {
    if(min(ring_size.x,ring_size.y)<=0.0) return vec4(0.0);
    float inner=min(min(coords.x,coords.y),min(ring_size.x-coords.x,ring_size.y-coords.y));
    if(inner>RIBBON_INSET || inner < -24.0) return vec4(0.0);
    float aa=0.65/max(umbriel_scale,0.01);
    float perimeter=ribbon_perimeter(), t=umbriel_time;
    vec2 path=ribbon_project(coords);
    float cycles=max(2.0,floor(perimeter/155.0));
    float phase=(path.x-t*48.0)/perimeter * cycles*2.0*RIBBON_PI;
    float wave=ribbon_wave(path.x,perimeter);
    float twist=sin(phase-t*0.65+0.9);
    float width=2.4+1.8*(0.5+0.5*twist);
    float across=path.y-wave;
    float edge=abs(across)-width;
    float alpha=(1.0-smoothstep(-aa,aa,edge))*0.88;
    float satin=exp(-pow((across+width*0.35)/max(width*0.6,0.1),2.0));
    vec3 color=mix(theme_color(vec3(0.66,0.035,0.27), 0.75),theme_color(vec3(1.0,0.34,0.61), 0.75),0.5+0.5*twist);
    color=mix(color,theme_color(vec3(1.0,0.78,0.86), 0.75),satin*0.72);
    float trim=exp(-pow((abs(across)-width+0.6)/0.5,2.0));
    color=mix(color,theme_color(vec3(1.0,0.68,0.81), 0.75),trim*0.5);
    float glow=exp(-abs(across)*0.32)*0.10;
    vec4 paint=vec4(theme_color(vec3(1.0,0.22,0.50), 0.75)*glow,glow);
    paint=ribbon_over(paint,vec4(color*alpha,alpha));

    // Use nearby hearts only, keeping the cost constant for large windows.
    float count=max(4.0,floor(perimeter/108.0));
    float spacing=perimeter/count;
    float nearest=floor((path.x-t*48.0)/spacing+0.5);
    for(int neighbor=-1;neighbor<=1;neighbor++) {
        float index=mod(nearest+float(neighbor),count);
        float along=index*spacing+t*48.0;
        vec4 frame=ribbon_frame(along);
        vec2 outward=vec2(frame.w,-frame.z);
        float sway=ribbon_wave(along,perimeter);
        // Heart tips rest near the ribbon; lobes stay within the window.
        vec2 center=frame.xy+outward*min(-5.5,sway-4.5);
        vec2 delta=coords-center;
        vec2 p=vec2(dot(delta,frame.zw),dot(delta,outward));
        if(max(abs(p.x),abs(p.y))>12.0) continue;
        float beat=fract(t*1.35+index/count*0.30);
        float pulse=exp(-pow((beat-0.16)/0.065,2.0))
            +0.55*exp(-pow((beat-0.36)/0.075,2.0));
        float size=(8.0+0.7*sin(index*2.4))*(1.0+0.16*pulse)*ribbon_scale();
        float tilt=0.20*sin(t*1.5+index*1.7);
        p=vec2(cos(tilt)*p.x-sin(tilt)*p.y,sin(tilt)*p.x+cos(tilt)*p.y);
        vec2 heart=vec2(p.x,-p.y)/max(size,0.01)+vec2(0.0,0.53);
        float d=ribbon_heart(heart)*size;
        float rim=(1.0-smoothstep(-aa,aa,d-0.65))*0.95;
        vec3 rim_color=theme_color(vec3(1.0,0.77,0.86), 0.75);
        paint=ribbon_over(paint,vec4(rim_color*rim,rim));
        float fill=(1.0-smoothstep(-aa,aa,d+0.35))*0.98;
        vec3 heart_color=mix(theme_color(vec3(0.87,0.045,0.32), 0.75),theme_color(vec3(1.0,0.34,0.56), 0.75),clamp(0.55-p.y/size,0.0,1.0));
        float highlight=exp(-dot((p-vec2(-size*0.22,-size*0.26))/vec2(size*0.13,size*0.18),
            (p-vec2(-size*0.22,-size*0.26))/vec2(size*0.13,size*0.18)));
        heart_color=mix(heart_color,theme_color(vec3(1.0,0.90,0.94), 0.75),highlight*0.86);
        paint=ribbon_over(paint,vec4(heart_color*fill,fill));
    }
    return vec4(paint.rgb/max(paint.a,0.0001),paint.a);
}

vec4 border(vec2 uv) {
    vec4 c = ring_color((uv - umbriel_border_hole.xy) * umbriel_size);
    return vec4(c.rgb * c.a, c.a);
}
