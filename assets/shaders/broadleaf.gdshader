shader_type spatial;
render_mode cull_disabled;
uniform sampler2D leaf_tex:source_color,filter_linear_mipmap_anisotropic;
varying vec2 local_uv;
void vertex(){
 local_uv=UV2;
 vec3 world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 VERTEX.x+=sin(TIME*1.1+world.x*0.3+world.z*0.2)*0.035;
}
void fragment(){
 vec4 leaf=texture(leaf_tex,UV);
 float shape=1.0-smoothstep(0.67,1.0,length(local_uv*2.0-1.0));
 ALPHA=leaf.a*shape;
 ALPHA_SCISSOR_THRESHOLD=0.42;
 ALBEDO=leaf.rgb*COLOR.rgb*vec3(0.72,0.89,0.68);
 ROUGHNESS=0.9;
 BACKLIGHT=vec3(0.16,0.22,0.06);
}
