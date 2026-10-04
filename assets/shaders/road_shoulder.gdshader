shader_type spatial;
render_mode cull_disabled;
uniform sampler2D grass_tex:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D gravel_tex:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform float half_width=3.0;
void fragment(){
 float lateral=abs(UV.x*4.0);
 float irregular=sin(UV.y*3.1)*0.13+sin(UV.y*12.8)*0.06;
 float blend=smoothstep(half_width-0.25,half_width+1.25,lateral+irregular);
 vec3 soil=texture(gravel_tex,UV*1.65).rgb*vec3(0.83,0.79,0.71);
 vec3 grass=texture(grass_tex,UV*0.5).rgb*vec3(0.66,0.72,0.57);
 ALBEDO=mix(soil,grass,blend);ROUGHNESS=0.98;
}
