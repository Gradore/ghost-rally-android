shader_type spatial;
render_mode cull_disabled;
// UV.x follows the circumference; UV.y crosses the rounded sidewall.
void fragment() {
 float tread = smoothstep(0.20,0.38,UV.y)*(1.0-smoothstep(0.62,0.80,UV.y));
 float stripe = abs(fract(UV.x*58.0+abs(UV.y-0.5)*5.0)-0.5);
 float groove = 1.0-smoothstep(0.045,0.10,stripe);
 float lane = 1.0-smoothstep(0.010,0.025,abs(abs(UV.y-0.5)-0.085));
 float ribs = 1.0-smoothstep(0.03,0.08,abs(fract(UV.y*28.0)-0.5));
 vec3 rubber = mix(vec3(0.036,0.042,0.044),vec3(0.017,0.019,0.020),max(groove,lane)*tread);
 ALBEDO = rubber*(1.0-ribs*0.10*(1.0-tread));
 ROUGHNESS = mix(0.83,0.98,tread);
 SPECULAR = 0.30;
}
