shader_type spatial;
render_mode cull_disabled, alpha_to_coverage;
uniform sampler2D leaf_tex:source_color,filter_linear_mipmap_anisotropic;
varying vec2 local_uv;
void vertex(){
 local_uv=UV2;
 vec3 world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 VERTEX.x+=sin(TIME*1.1+world.x*0.3+world.z*0.2)*0.035;
}
void fragment(){
 vec4 leaf=texture(leaf_tex,UV);
 vec2 p=local_uv*2.0-1.0;
 float angle=atan(p.y,p.x);
 float irregular=0.10*sin(angle*9.0)+0.07*sin(angle*17.0+1.3);
 float shape=1.0-smoothstep(0.64,0.88,length(p)+irregular);
 ALPHA=leaf.a*shape;
 ALPHA_SCISSOR_THRESHOLD=0.36;
 ALPHA_ANTIALIASING_EDGE=0.20;
 ALPHA_TEXTURE_COORDINATE=UV*vec2(textureSize(leaf_tex,0));
 ALBEDO=leaf.rgb*COLOR.rgb*vec3(0.66,0.81,0.60);
 ROUGHNESS=0.9;
 BACKLIGHT=vec3(0.16,0.22,0.06);
}
