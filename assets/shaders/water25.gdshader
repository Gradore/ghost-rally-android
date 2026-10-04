shader_type spatial;
varying vec3 wp;
void vertex(){wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 float p=wp.x*1.8+wp.z*0.65+TIME*1.3;
 float q=wp.x*0.52-wp.z*2.8+TIME*0.93;
 float r=wp.x*5.6+wp.z*4.1+TIME*1.71;
 vec3 n=normalize(vec3(cos(p)*0.085+cos(q)*0.026+cos(r)*0.016,1.0,cos(p)*0.032-cos(q)*0.14+cos(r)*0.012));
 NORMAL=normalize(mat3(VIEW_MATRIX)*n);
 float fresnel=pow(1.0-clamp(dot(NORMAL,VIEW),0.0,1.0),5.0);
 ALBEDO=mix(vec3(0.018,0.072,0.084),vec3(0.12,0.20,0.24),fresnel);
 ROUGHNESS=0.18;METALLIC=0.0;SPECULAR=0.85;
}
