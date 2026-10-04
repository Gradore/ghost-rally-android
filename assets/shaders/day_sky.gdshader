shader_type sky;
uniform vec3 sun_direction=vec3(0.53,0.37,0.76);
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
float clouds(vec2 p){float n=0.0;float a=0.5;for(int i=0;i<5;i++){n+=noise(p)*a;p=p*2.02+vec2(17,9);a*=0.5;}return n;}
void sky(){
 float elevation=max(EYEDIR.y,0.0);
 vec3 blue=mix(vec3(0.72,0.82,0.88),vec3(0.11,0.36,0.65),pow(elevation,0.35));
 vec2 p=EYEDIR.xz/max(0.3,elevation)*2.2;
 float n=clouds(p);
 float cover=smoothstep(0.48,0.72,n)*smoothstep(0.22,0.40,elevation);
 vec3 cloud=mix(vec3(0.59,0.67,0.73),vec3(0.98,0.97,0.93),smoothstep(0.46,0.68,n));
 float toward_sun=max(dot(normalize(sun_direction),EYEDIR),0.0);
 float haze=pow(toward_sun,18.0)*(1.0-cover*0.8);
 vec3 horizon=mix(blue,vec3(0.95,0.77,0.53),haze*0.22);
 float disc=smoothstep(0.99991,0.99998,toward_sun);
 COLOR=mix(horizon,cloud,cover)+vec3(1.0,0.82,0.57)*(pow(toward_sun,280.0)*0.16+disc*1.8)*(1.0-cover);
 if(EYEDIR.y<0.0){COLOR=mix(vec3(0.16,0.21,0.14),vec3(0.46,0.52,0.42),pow(1.0+EYEDIR.y,6.0));}
}
