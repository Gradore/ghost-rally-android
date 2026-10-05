shader_type spatial;
render_mode cull_disabled;
uniform sampler2D brick_color:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D brick_normal:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D brick_rough:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D plaster_color:source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D plaster_normal:filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D plaster_rough:filter_linear_mipmap_anisotropic,repeat_enable;
uniform int kind=6;
uniform vec4 tint:source_color=vec4(1.0);
uniform bool vertex_tint=false;
varying vec3 wp;
varying vec3 wn;
void vertex(){wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;wn=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
void fragment(){
 vec3 col=tint.rgb*(vertex_tint?COLOR.rgb:vec3(1));
 bool brick=kind==1 || (kind==6 && col.r>col.g*1.22 && col.r>col.b*1.25);
 bool xface=abs(wn.x)>abs(wn.z);
 vec2 uv=vec2(xface?wp.z:wp.x,wp.y)/(brick?2.0:1.0);
 vec3 base=brick?texture(brick_color,uv).rgb:texture(plaster_color,uv).rgb;
 vec3 bump=(brick?texture(brick_normal,uv).rgb:texture(plaster_normal,uv).rgb)*2.0-1.0;
 float rough=brick?texture(brick_rough,uv).r:texture(plaster_rough,uv).r;
 ALBEDO=clamp(brick?base*col/vec3(0.36,0.16,0.09):base*col/vec3(0.82),vec3(0.012),vec3(0.9));
 vec3 u=xface?vec3(0,0,1):vec3(1,0,0);
 vec3 v=abs(wn.y)>0.7?vec3(0,0,1):vec3(0,1,0);
 NORMAL=normalize((VIEW_MATRIX*vec4(normalize(wn*bump.z+u*bump.x*0.38+v*bump.y*0.38),0)).xyz);
 ROUGHNESS=clamp(rough,0.62,1.0);SPECULAR=0.25;
}
