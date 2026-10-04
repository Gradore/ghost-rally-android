shader_type spatial;
render_mode cull_disabled;
uniform sampler2D relief : filter_linear;
uniform sampler2D grass : source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform vec2 low;
uniform vec2 span;
varying vec2 world_uv;
varying vec3 wp;
void vertex(){
 wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 world_uv=(wp.xz-low)/span;
 VERTEX.y=texture(relief,world_uv).r*6.0-6.0;
 vec2 e=vec2(1.0/512.0,0.0);
 float dx=(texture(relief,world_uv+e).r-texture(relief,world_uv-e).r)*6.0/(span.x/256.0);
 float dz=(texture(relief,world_uv+e.yx).r-texture(relief,world_uv-e.yx).r)*6.0/(span.y/256.0);
 NORMAL=normalize(vec3(-dx,1.0,-dz));
}
void fragment(){
 if(texture(relief,world_uv).b>0.5){discard;}
 ALBEDO=texture(grass,wp.xz/8.0).rgb*vec3(0.68,0.72,0.63);
 ROUGHNESS=1.0;
}
