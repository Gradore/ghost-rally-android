shader_type spatial;
varying vec3 floor_position;
void vertex(){floor_position=VERTEX;}
void fragment(){
 vec2 p=floor_position.xz*0.55;vec2 aa=fwidth(p)*1.4;
 vec2 line=smoothstep(vec2(0.004)-aa,vec2(0.004)+aa,min(fract(p),1.0-fract(p)));
 float seam=1.0-min(line.x,line.y);
 float grain=fract(sin(dot(floor_position.xz,vec2(31.2,18.7)))*471.7);
 ALBEDO=mix(vec3(0.11,0.14,0.16),vec3(0.045,0.06,0.075),seam)*(0.98+grain*0.025);
 ROUGHNESS=0.32;METALLIC=0.18;
}
