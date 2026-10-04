shader_type spatial;
render_mode cull_disabled;
varying float tip;
varying float variation;
void vertex(){
 tip=UV.y;
 variation=fract(sin(dot(MODEL_MATRIX[3].xz+VERTEX.xz,vec2(13.1,7.3)))*143.2);
 vec3 world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 VERTEX.x+=sin(TIME*1.6+world.x*0.35+world.z*0.21)*0.06*tip*tip;
}
void fragment(){
 vec3 root=vec3(0.10,0.18,0.045);
 vec3 top=mix(vec3(0.30,0.39,0.10),vec3(0.46,0.45,0.19),variation);
 ALBEDO=mix(root,top,tip)*COLOR.rgb;
 ROUGHNESS=0.94;
 BACKLIGHT=vec3(0.18,0.23,0.07)*tip;
}
