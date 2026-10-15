// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Barrulus
// Time-aware path interpolation adapted from Train Tracks / Comet / Noctalia.
const float TRAIL_LIFE = 1.10; // Seconds; bounded by retained pointer history.
const float MAX_LENGTH = 240.0; // Logical pixels of path behind the pointer.
const float STRENGTH = 0.95; // 0..1, artwork opacity.

const vec3 PEARL = vec3(0.95, 0.98, 1.0);
const vec3 MINT = vec3(0.65, 0.89, 0.83);
const vec3 LAVENDER = vec3(0.80, 0.74, 0.94);
const float TAU = 6.28318530718;

float gc_hash(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    q += dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z);
}
float gc_noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(gc_hash(i), gc_hash(i + vec2(1.0, 0.0)), f.x),
               mix(gc_hash(i + vec2(0.0, 1.0)), gc_hash(i + vec2(1.0)), f.x), f.y);
}
vec2 gc_point(vec2 a, vec2 b, vec2 m0, vec2 m1, float t) {
    float t2 = t * t, t3 = t2 * t;
    return (2.0*t3-3.0*t2+1.0)*a + (t3-2.0*t2+t)*m0
         + (3.0*t2-2.0*t3)*b + (t3-t2)*m1;
}
// Walk from newest to oldest; measure every segment before rejecting pixels.
// nearest = distance, signed sideways distance, age, stable birth phase.
void gc_segment(vec2 here, vec4 p0, vec4 p1, vec4 p2, vec4 p3,
                inout float distanceBehind, inout vec4 nearest, inout vec2 meta) {
    vec2 a = p1.xy * umbriel_size, b = p2.xy * umbriel_size;
    vec2 chord = b - a;
    float lengthChord = length(chord);
    if (lengthChord > 800.0 || p2.z >= TRAIL_LIFE) {
        distanceBehind = MAX_LENGTH;
        return;
    }
    if (lengthChord < 0.25) return;
    if (length((p0.xy-p1.xy)*umbriel_size) > 800.0) p0 = p1;
    if (length((p3.xy-p2.xy)*umbriel_size) > 800.0) p3 = p2;
    float dt = max(p1.z-p2.z, 0.001);
    vec2 m0 = (b-p0.xy*umbriel_size)*dt/max(p0.z-p2.z, 0.001);
    vec2 m1 = (p3.xy*umbriel_size-a)*dt/max(p1.z-p3.z, 0.001);
    m0 *= min(1.0, 1.5*lengthChord/max(length(m0), 0.001));
    m1 *= min(1.0, 1.5*lengthChord/max(length(m1), 0.001));
    float arcLength = 0.0;
    vec2 previous = a;
    for (int j = 1; j <= 6; ++j) {
        vec2 point = gc_point(a,b,m0,m1,float(j)/6.0);
        arcLength += length(point-previous);
        previous = point;
    }
    float segmentStart = distanceBehind;
    distanceBehind += arcLength;
    float bulge = (4.0/27.0)*(length(m0-chord)+length(m1-chord));
    float projection = clamp(dot(here-a,chord)/dot(chord,chord),0.0,1.0);
    if (length(here-a-projection*chord) > 20.0+bulge) return;
    float travelled = 0.0;
    previous = a;
    for (int j = 1; j <= 6; ++j) {
        vec2 point = gc_point(a,b,m0,m1,float(j)/6.0);
        vec2 edge = point-previous;
        float pieceLength = length(edge);
        // Clip a long piece to the live tail before finding its nearest point.
        // A fast sweep must still leave its newest MAX_LENGTH pixels visible.
        float lowerLength = (segmentStart+arcLength-travelled-MAX_LENGTH)/max(pieceLength,0.001);
        float oldestT = (p1.z-TRAIL_LIFE)/dt;
        float lowerAge = oldestT*6.0-float(j-1);
        float lower = max(0.0,max(lowerLength,lowerAge));
        if (lower <= 1.0 && pieceLength > 0.001) {
            float u = clamp(dot(here-previous,edge)/dot(edge,edge),lower,1.0);
            float t = (float(j-1)+u)/6.0;
            vec2 delta = here-mix(previous,point,u);
            float d = length(delta);
            float age = mix(p1.z,p2.z,t);
            if (d < nearest.x && age < TRAIL_LIFE) {
                vec2 tangent = edge/pieceLength;
                float birth = p1.w + mod(p2.w-p1.w+60.0,60.0)*t;
                nearest = vec4(d,dot(delta,vec2(-tangent.y,tangent.x)),age,birth);
                meta = vec2(segmentStart+arcLength-travelled-u*pieceLength,lengthChord/dt);
            }
        }
        travelled += pieceLength;
        previous = point;
    }
}
void gc_path(vec2 here, out vec4 nearest, out vec2 meta) {
    nearest = vec4(20.0,0.0,TRAIL_LIFE,0.0);
    meta = vec2(MAX_LENGTH,0.0);
    vec4 p0=vec4(0.0), p1=p0, p2=p0, p3=p0;
    float behind = 0.0;
    for (int k = 63; k >= 0; --k) {
        if (behind >= MAX_LENGTH) break;
        if (k < umbriel_pointer_count) {
            vec4 next = umbriel_pointer_path[k];
            if (k == umbriel_pointer_count-1) { p0=next; p1=next; p2=next; }
            p3=p2; p2=p1; p1=p0; p0=next;
            if (k < umbriel_pointer_count-2)
                gc_segment(here,p0,p1,p2,p3,behind,nearest,meta);
        }
    }
    if (umbriel_pointer_count >= 2 && behind < MAX_LENGTH)
        gc_segment(here,p0,p0,p1,p2,behind,nearest,meta);
}

float gc_idle(vec2 delta) {
    float t = umbriel_time;
    float result = 0.0;
    for (int i=0; i<2; ++i) {
        float n=float(i), side=i==0 ? -1.0 : 1.0;
        vec2 q=delta-vec2(-7.0+n*13.0,6.0+n*3.0);
        float bend=sin(q.y*0.6+t*1.2+n*2.0)*1.0;
        float curl=exp(-pow((q.x-side*bend)/0.95,2.0)-pow(q.y/3.4,2.0));
        result+=curl*(0.07+0.08*pow(0.5+0.5*sin(t*1.4+n*2.5),2.0));
    }
    return result*(1.0-smoothstep(14.0,19.0,length(delta)));
}
vec2 gc_art(vec4 path, vec2 meta) {
    float age=path.z*(0.48/TRAIL_LIFE), across=path.y;
    float phase=mod(path.w,60.0)*TAU/60.0;
    vec2 flow=vec2(cos(phase),sin(phase))*145.0;
    float noise=gc_noise(flow+vec2(across*0.11,age*2.0));
    float centre=sin(phase*73.0+age*8.0)*(0.45+age*4.0);
    float d=abs(across-centre);
    float core=1.0-smoothstep(0.45,0.95+0.5/max(umbriel_scale,0.01),d);
    float broken=0.30+0.70*smoothstep(0.25,0.60,noise);
    float peel=abs(across-centre-sin(phase*47.0)*(1.5+age*19.0));
    float wisps=exp(-peel*peel/3.0)*smoothstep(0.02,0.12,age)
               *(1.0-smoothstep(0.18,TRAIL_LIFE,age));
    float haste=smoothstep(220.0,900.0,meta.y);
    float flecks=wisps*smoothstep(0.55,0.78,gc_noise(flow*2.0+age*3.0))*haste;
    float alpha=core*broken*0.76+exp(-d*d/9.0)*0.09+wisps*0.25+flecks*0.22;
    return vec2(alpha,clamp(core*0.8+flecks,0.0,1.0));
}

vec4 cursor(vec2 uv) {
    vec4 source=umbriel_sample(uv);
    vec2 delta=(uv-umbriel_pointer)*umbriel_size;
    float tip=smoothstep(3.0,8.0,length(delta));
    vec4 path; vec2 meta;
    gc_path(uv*umbriel_size,path,meta);
    float life=(1.0-smoothstep(TRAIL_LIFE*0.25,TRAIL_LIFE,path.z))
              *(1.0-smoothstep(MAX_LENGTH*0.60,MAX_LENGTH,meta.x));
    vec2 art=vec2(0.0);
    if (life>0.0 && path.x<20.0) art=gc_art(path,meta);
    float trail=art.x*life*(1.0-smoothstep(16.0,20.0,path.x));
    // At the newest endpoint, signed sideways distance alone describes an
    // infinite ribbon. Remove its axial extension, keeping curved joins intact.
    float beyondTip=sqrt(max(0.0,path.x*path.x-path.y*path.y));
    if (meta.x<0.01) trail*=1.0-smoothstep(0.0,1.0,beyondTip);
    float idle=gc_idle(delta);
    float alpha=clamp(max(trail,idle)*tip*clamp(STRENGTH,0.0,1.0),0.0,0.85);
    float hue=0.5+0.5*sin(mod(path.w,60.0)*TAU/60.0*19.0);
    vec3 tint=mix(MINT,LAVENDER,hue);
    vec3 color=mix(tint,PEARL,0.30+0.65*art.y);
    color=mix(mix(MINT,PEARL,0.65),color,trail/max(max(trail,idle),0.0001));
    return vec4(mix(source.rgb,color*source.a,alpha),source.a);
}
