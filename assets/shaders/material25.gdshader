shader_type spatial;
render_mode cull_disabled;
uniform sampler2D atlas:source_color,filter_linear_mipmap_anisotropic,repeat_disable;
uniform int kind=0;
uniform vec4 tint:source_color=vec4(1.0);
uniform bool vertex_tint=false;
varying vec3 wp;
varying vec3 wn;
void vertex(){wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;wn=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
vec3 sample_tile(vec2 uv,int tile){
 vec2 cell=vec2(float(tile%3),float(tile/3));
 vec2 local=mix(vec2(0.012),vec2(0.988),fract(uv));
 // Explicit gradients avoid selecting a coarse mip at every wrap seam.
 return textureGrad(atlas,(cell+local)/vec2(3,2),dFdx(uv)/vec2(3,2),dFdy(uv)/vec2(3,2)).rgb;
}
void fragment(){
 vec3 col=tint.rgb*(vertex_tint?COLOR.rgb:vec3(1));
 int tile=kind;
 if(kind==6){tile=(col.r>col.g*1.22 && col.r>col.b*1.25)?1:2;}
 vec2 uv=wp.xz/(tile==0?1.2:3.0);
 if(tile==1 || tile==2){
  vec3 n=abs(wn);uv=vec2(n.x>n.z?wp.z:wp.x,wp.y)/(tile==1?1.7:0.75);
 }
 if(tile==4){uv=wp.xz/1.0;}
 vec3 detail=sample_tile(uv,tile);
 vec3 macro=sample_tile(uv*0.083+vec2(0.37,0.17),tile);
 float variation=mix(0.9,1.08,macro.r);
 if(tile==1){detail*=col/max(vec3(0.48,0.22,0.13),vec3(0.08));}
 else if(tile==2){detail=mix(col*0.8,detail*col/vec3(0.78,0.75,0.68),0.25);}
 else{detail*=col;}
 ALBEDO=clamp(detail*variation,vec3(0.015),vec3(0.85));
 ROUGHNESS=tile==0?0.87:0.96;
 SPECULAR=tile==0?0.3:0.2;
}
