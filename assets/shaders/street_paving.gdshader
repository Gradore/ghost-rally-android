shader_type spatial;
render_mode cull_disabled;
uniform vec4 tint : source_color = vec4(0.62,0.63,0.59,1.0);
varying vec3 world_point;
void vertex(){world_point=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec2 p=world_point.xz/vec2(0.20,0.10);p.x+=mod(floor(p.y),2.0)*0.5;
 vec2 e=min(fract(p),1.0-fract(p));vec2 aa=fwidth(p);
 float joint=smoothstep(0.02-aa.x,0.04+aa.x,e.x)*smoothstep(0.02-aa.y,0.04+aa.y,e.y);
 float variation=fract(sin(dot(floor(p),vec2(17.1,43.7)))*17471.1);
 ALBEDO=tint.rgb*mix(0.68,0.94+variation*0.06,joint);ROUGHNESS=0.91;
}
