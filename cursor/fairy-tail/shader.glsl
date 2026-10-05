// Long, curved, multicolour fairy tail. Separate from the bundled short trail.
vec2 fairyCurve(vec2 p0, vec2 p1, vec2 p2, vec2 p3, float t) {
    vec2 point = 0.5 * ((2.0*p1) + (-p0+p2)*t
        + (2.0*p0-5.0*p1+4.0*p2-p3)*t*t + (-p0+3.0*p1-3.0*p2+p3)*t*t*t);
    return clamp(point, min(p1,p2)-vec2(24.0), max(p1,p2)+vec2(24.0));
}
float fairyHash(float x) { return fract(sin(x * 127.1) * 43758.5453); }
vec3 fairyColour(float birth) {
    vec3 blue = umbriel_palette_count > 0 ? umbriel_palette_at(0.0).rgb : vec3(0.48,0.64,1.0);
    vec3 gold = umbriel_palette_count > 0 ? umbriel_palette_at(0.25).rgb : vec3(0.96,0.79,0.42);
    float phase = fract(birth * 0.35) * 3.0;
    vec3 lavender = vec3(0.72,0.48,0.96);
    if (phase < 1.0) return mix(blue,lavender,smoothstep(0.0,1.0,phase));
    if (phase < 2.0) return mix(lavender,gold,smoothstep(1.0,2.0,phase));
    return mix(gold,blue,smoothstep(2.0,3.0,phase));
}
vec4 cursor(vec2 uv) {
    vec4 background = umbriel_sample(uv);
    vec2 pixel = uv * umbriel_size;
    float tip = smoothstep(10.0,20.0,length((uv-umbriel_pointer)*umbriel_size));
    if (tip <= 0.0) return background;
    vec3 result = background.rgb;
    for (int i=0; i<63; ++i) {
        if (i+1 < umbriel_pointer_count) {
            vec4 a=umbriel_pointer_path[i];
            vec4 b=umbriel_pointer_path[i+1];
            vec2 p1=a.xy*umbriel_size, p2=b.xy*umbriel_size;
            vec2 outside=max(max(min(p1,p2)-pixel,pixel-max(p1,p2)),vec2(0.0));
            if (max(outside.x,outside.y)>100.0) continue;
            vec2 p0=p1, p3=p2;
            if (i>0) p0=umbriel_pointer_path[i-1].xy*umbriel_size;
            if (i+2<umbriel_pointer_count) p3=umbriel_pointer_path[i+2].xy*umbriel_size;
            float best=1e10, along=0.0;
            vec2 prev=p1;
            for (int step=1; step<=4; ++step) {
                float t=float(step)*0.25;
                vec2 next=fairyCurve(p0,p1,p2,p3,t);
                vec2 v=next-prev;
                float local=clamp(dot(pixel-prev,v)/max(dot(v,v),0.001),0.0,1.0);
                float d=length(pixel-mix(prev,next,local));
                if (d<best) { best=d; along=(float(step-1)+local)*0.25; }
                prev=next;
            }
            float age=mix(a.z,b.z,along);
            float life=1.0-smoothstep(0.9,2.0,age);
            float width=8.0+19.0*smoothstep(0.0,0.8,age);
            float roll=0.88+0.12*sin(best*0.14-age*2.0+sin(age*3.0));
            float body=exp(-best*best/(width*width))*roll;
            float veil=exp(-best*best/(width*width*3.0))*0.13;
            // Walk oldest to newest, so a new loop draws over its own older tail.
            vec3 colour=fairyColour(mix(a.w,b.w,along));
            result=mix(result,colour,(body+veil)*life*0.48*tip);
            // Persistent grains and tiny stars drift slowly beside the ribbon.
            for (int j=0;j<2;++j) {
                float seed=a.w*71.0+float(j)*19.0;
                float r=fairyHash(seed), s=fairyHash(seed+7.0);
                float t=0.2+0.6*r;
                float dustAge=mix(a.z,b.z,t);
                float dustLife=1.0-smoothstep(0.7,2.0,dustAge);
                vec2 tangent=normalize(p2-p1+vec2(0.001));
                vec2 normal=vec2(-tangent.y,tangent.x);
                vec2 centre=fairyCurve(p0,p1,p2,p3,t)+normal*(s-0.5)*(14.0+22.0*dustAge);
                centre+=normal*sin(dustAge*2.0+r*6.28)*3.0;
                vec2 d=pixel-centre;
                if (dot(d,d)>225.0) continue;
                float grain=exp(-dot(d,d)/1.8);
                float glow=exp(-dot(d,d)/20.0)*0.12;
                float star=0.0;
                if (r>0.7) {
                    float angle=r*6.28+dustAge*0.35;
                    vec2 q=mat2(cos(angle),-sin(angle),sin(angle),cos(angle))*d;
                    star=(exp(-abs(q.x)*3.5-abs(q.y)/3.0)+exp(-abs(q.y)*3.5-abs(q.x)/3.0))*0.7;
                }
                float twinkle=0.8+0.2*sin(dustAge*4.0+s*6.28);
                float alpha=clamp(grain+glow+star,0.0,0.9)*dustLife*twinkle*tip;
                result=mix(result,mix(fairyColour(a.w),vec3(1.0,0.97,0.86),0.65),alpha);
            }
        }
    }
    // Soften the whole cloud, including overlapping ribbons and sparkles, near text.
    float pointerDistance = length((uv - umbriel_pointer) * umbriel_size);
    float headStrength = mix(0.4, 1.0, smoothstep(12.0, 52.0, pointerDistance));
    return vec4(mix(background.rgb, result, headStrength), background.a);
}
