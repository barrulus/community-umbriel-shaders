// Adapted from shaders/window/pink-purple-clouds.glsl

// Theme colours affect artwork only; palette = false restores the original RGB.
// Keep the original shade and soften highlights without changing effect opacity.
vec3 theme_color(vec3 original, float position) {
    if (umbriel_palette_count <= 0) return original;
    float value = max(original.r, max(original.g, original.b));
    float white = min(original.r, min(original.g, original.b)) / max(value, 0.0001);
    return value * mix(umbriel_palette_at(position).rgb, vec3(1.0), white * 0.75);
}

vec4 tex2D_screen(vec2 uv) { return umbriel_sample(uv); }
vec2 migration_buffer_size() { return umbriel_size * umbriel_scale; }
#define umbriel_size migration_buffer_size()
// Pink and purple clouds: slow curling billows, translucent over window content.
// Keep the source alpha and premultiplication, including transparent corners.
float cloud_hash(vec2 p) {
    vec3 q=fract(vec3(p.xyx)*0.1031);
    q+=dot(q,q.yzx+33.33);
    return fract((q.x+q.y)*q.z);
}
float cloud_noise(vec2 p) {
    vec2 cell=floor(p), f=fract(p);
    f=f*f*(3.0-2.0*f);
    return mix(mix(cloud_hash(cell),cloud_hash(cell+vec2(1.0,0.0)),f.x),
               mix(cloud_hash(cell+vec2(0.0,1.0)),cloud_hash(cell+vec2(1.0)),f.x),f.y);
}
float cloud_fbm(vec2 p) {
    float value=0.0, weight=0.5;
    for(int octave=0;octave<4;octave++) {
        value+=cloud_noise(p)*weight;
        p=mat2(0.80,-0.60,0.60,0.80)*p*2.03+vec2(7.1,3.8);
        weight*=0.5;
    }
    return value;
}
vec2 cloud_curl(vec2 p,vec2 center,float strength) {
    vec2 q=p-center;
    float angle=strength*exp(-dot(q,q)*0.48);
    return center+mat2(cos(angle),-sin(angle),sin(angle),cos(angle))*q;
}
vec4 postprocess(vec3 coords) {
    vec4 source=tex2D_screen(coords.xy);
    if(source.a<=0.0) return source;
    float t=umbriel_time;
    float aspect=umbriel_size.x/max(umbriel_size.y,1.0);
    vec2 p=(coords.xy-0.5)*vec2(aspect,1.0)*3.6;
    p=cloud_curl(p,vec2(-0.65,0.25),1.9*sin(t*0.16)+1.3);
    p=cloud_curl(p,vec2(0.95,-0.45),-1.6*cos(t*0.13)-1.0);
    vec2 q=vec2(cloud_fbm(p*0.75+vec2(0.0,t*0.12)),
                cloud_fbm(p*0.75+vec2(5.2,-t*0.105)));
    vec2 warp=p+(q-0.47)*2.8+vec2(0.0,t*0.045);
    vec2 folds=vec2(cloud_fbm(warp+vec2(1.7,t*0.035)),
                    cloud_fbm(warp+vec2(8.3,-t*0.05)));
    vec2 domain=warp+(folds-0.47)*1.65;
    float density=cloud_fbm(domain);
    float light_sample=cloud_fbm(domain+vec2(-0.12,-0.20));
    float lit=clamp(0.56+(density-light_sample)*2.8,0.1,1.0);
    float body=smoothstep(0.28,0.70,density);
    float hue=smoothstep(0.27,0.68,cloud_fbm(domain*0.62+vec2(13.2,4.6)));
    vec3 purple=theme_color(vec3(0.43,0.14,0.76), 0.0), pink=theme_color(vec3(1.0,0.38,0.70), 0.75);
    vec3 cloud=mix(purple,pink,hue);
    cloud*=0.76+0.30*lit;
    cloud=mix(cloud,theme_color(vec3(0.96,0.75,1.0), 0.0),body*lit*0.30);
    float coverage=0.13+0.43*body;
    // Give fine text strokes more of their original contrast.
    vec3 original=source.rgb/source.a;
    vec2 pixel=1.5*max(umbriel_scale,0.01)/max(umbriel_size,vec2(1.0));
    vec4 nearby_x=tex2D_screen(clamp(coords.xy+vec2(pixel.x,0.0),0.0,1.0));
    vec4 nearby_y=tex2D_screen(clamp(coords.xy+vec2(0.0,pixel.y),0.0,1.0));
    vec3 nx=nearby_x.a>0.0 ? nearby_x.rgb/nearby_x.a : original;
    vec3 ny=nearby_y.a>0.0 ? nearby_y.rgb/nearby_y.a : original;
    float contrast=max(length(original-nx),length(original-ny));
    coverage*=1.0-0.60*smoothstep(0.10,0.55,contrast);
    vec3 result=mix(original,clamp(cloud,0.0,1.0),coverage);
    return vec4(result*source.a,source.a);
}

vec4 window(vec2 uv) { return postprocess(vec3(uv, 0.0)); }
