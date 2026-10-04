shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;
void fragment(){
 vec2 p=(UV-0.5)*2.0;
 float coverage=(1.0-smoothstep(0.45,1.0,abs(p.x)))*(1.0-smoothstep(0.45,1.0,abs(p.y)));
 ALBEDO=vec3(0.005,0.009,0.012);ALPHA=coverage*0.52;
}
