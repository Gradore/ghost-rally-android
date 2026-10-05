shader_type spatial;
render_mode cull_disabled;
uniform vec4 paint_color:source_color=vec4(0.05,0.18,0.10,1.0);
uniform float dirt_amount=1.0;
varying vec3 panel_position;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex(){panel_position=VERTEX;}
void fragment(){
 float height=panel_position.y;
 float fleck=noise(panel_position.xz*47.0+vec2(height*13.0));
 float dirt=dirt_amount*(1.0-smoothstep(0.38,0.78,height))*smoothstep(0.3,0.8,noise(panel_position.xz*12.0));
 vec3 dust=vec3(0.26,0.22,0.15);
 ALBEDO=mix(paint_color.rgb*(0.96+fleck*0.06),dust,dirt*0.55);
 METALLIC=mix(0.28,0.04,dirt);
 ROUGHNESS=mix(0.27,0.9,dirt);
 CLEARCOAT=0.8*(1.0-dirt);
 CLEARCOAT_ROUGHNESS=0.28;
}
