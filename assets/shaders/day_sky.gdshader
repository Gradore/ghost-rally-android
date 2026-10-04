shader_type sky;
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
 COLOR=mix(blue,cloud,cover);
}
