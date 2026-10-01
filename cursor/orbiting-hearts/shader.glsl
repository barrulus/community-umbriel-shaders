// Adapted from shaders/cursor/orbiting-hearts.glsl
vec4 tex2D_screen(vec2 uv) { return umbriel_sample(uv); }
vec2 migration_buffer_size() { return umbriel_size * umbriel_scale; }
vec2 migration_pointer() { return umbriel_pointer * umbriel_size * umbriel_scale; }
#define umbriel_output_size migration_buffer_size()
#define umbriel_cursor migration_pointer()
#define umbriel_size migration_buffer_size()
vec4 hearts_over(vec4 under,vec4 paint) { return paint+under*(1.0-paint.a); }
float hearts_shape(vec2 p) {
    p.x=abs(p.x);
    if(p.x+p.y>1.0) return length(p-vec2(0.25,0.75))-0.35355339;
    vec2 a=p-vec2(0.0,1.0),b=p-0.5*max(p.x+p.y,0.0);
    return sqrt(min(dot(a,a),dot(b,b)))*sign(p.x-p.y);
}
vec4 postprocess(vec3 coords) {
    vec4 under=tex2D_screen(coords.xy);
    vec2 p=(coords.xy*umbriel_output_size-umbriel_cursor)/max(umbriel_scale,0.01);
    if(length(p)>58.0) return under;
    float aa=0.65/max(umbriel_scale,0.01);
    float dot_alpha=1.0-smoothstep(1.5-aa,1.5+aa,length(p));
    vec4 paint=vec4(vec3(1.0,0.88,0.96)*dot_alpha,dot_alpha);
    for(int i=0;i<6;i++) {
        float phase=float(i)*1.047197551;
        float angle=umbriel_time*0.85+phase;
        vec2 center=43.0*vec2(cos(angle),sin(angle));
        vec2 local=p-center;
        if(length(local)>11.0) continue;
        float tilt=0.17*sin(umbriel_time*1.4+phase);
        local=mat2(cos(tilt),-sin(tilt),sin(tilt),cos(tilt))*local;
        float beat=fract(umbriel_time*1.35+float(i)*0.08);
        float pulse=exp(-pow((beat-0.16)/0.07,2.0))+0.5*exp(-pow((beat-0.36)/0.08,2.0));
        float size=8.0*(1.0+0.15*pulse);
        float d=hearts_shape(vec2(local.x,-local.y)/size+vec2(0.0,0.53))*size;
        float outline=1.0-smoothstep(-aa,aa,d-0.85);
        paint=hearts_over(paint,vec4(vec3(0.28,0.07,0.25)*outline,outline)*0.8);
        float rim=1.0-smoothstep(-aa,aa,d-0.45);
        paint=hearts_over(paint,vec4(vec3(1.0,0.82,0.94)*rim,rim));
        float fill=1.0-smoothstep(-aa,aa,d+0.25);
        vec3 color=mod(float(i),2.0)<0.5 ? vec3(1.0,0.25,0.56) : vec3(0.74,0.34,0.95);
        color=mix(color,vec3(1.0,0.65,0.85),clamp(0.35-local.y/size,0.0,0.7));
        vec2 gleam=(local-vec2(-size*0.22,-size*0.26))/vec2(size*0.13,size*0.18);
        color=mix(color,vec3(1.0,0.96,1.0),exp(-dot(gleam,gleam))*0.9);
        paint=hearts_over(paint,vec4(color*fill,fill));
    }
    return hearts_over(under,paint);
}

vec4 cursor(vec2 uv) { return postprocess(vec3(uv, 0.0)); }
