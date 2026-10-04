shader_type spatial;
render_mode cull_disabled;
uniform sampler2D albedo_tex:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D normal_tex:hint_normal,filter_linear_mipmap_anisotropic,repeat_enable;
uniform vec4 tint:source_color=vec4(0.48,0.56,0.33,1);
uniform bool farmland=false;
varying vec3 wp;
void vertex(){wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec2 uv=wp.xz/10.0;vec3 fine=texture(albedo_tex,uv).rgb;
 float macro=texture(albedo_tex,uv*0.095+vec2(0.37,0.17)).r;
 float rows=0.91+0.09*sin((wp.x+wp.z*0.3)*9.0);
 float fade=1.0-smoothstep(40.0,160.0,length(VERTEX));
 ALBEDO=fine*tint.rgb*mix(1.55,2.0,macro)*(farmland?mix(1.0,rows,fade):1.0);
 NORMAL_MAP=texture(normal_tex,uv).rgb;NORMAL_MAP_DEPTH=0.6*fade;ROUGHNESS=0.97;
}
