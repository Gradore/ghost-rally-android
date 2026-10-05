shader_type spatial;
render_mode cull_disabled;
uniform sampler2D albedo_tex:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D normal_tex:hint_normal,filter_linear_mipmap_anisotropic,repeat_enable;
varying vec3 wp;
void vertex(){wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec2 uv=wp.xz/4.0;
 vec3 fine=texture(albedo_tex,uv).rgb;
 float macro=texture(albedo_tex,uv*0.08+vec2(0.13,0.61)).r;
 ALBEDO=fine*vec3(0.76,0.79,0.82)*mix(0.87,1.12,macro);
 NORMAL_MAP=texture(normal_tex,uv).rgb;NORMAL_MAP_DEPTH=0.5*(1.0-smoothstep(35.0,90.0,length(VERTEX)));
 ROUGHNESS=mix(0.78,0.95,macro);
}
