shader_type spatial;
render_mode cull_disabled;
void fragment(){
 vec2 p=UV*vec2(8.0,11.0);p.x+=mod(floor(p.y),2.0)*0.5;
 vec2 aa=fwidth(p);vec2 e=min(fract(p),1.0-fract(p));
 float seams=smoothstep(0.015-aa.x,0.035+aa.x,e.x)*smoothstep(0.02-aa.y,0.04+aa.y,e.y);
 float pitched=step(COLOR.g,COLOR.r*0.85);
 float tile=fract(sin(dot(floor(p),vec2(13.2,42.1)))*13474.2);
 ALBEDO=COLOR.rgb*mix(0.93,mix(0.67,0.92+tile*0.08,seams),pitched);ROUGHNESS=0.86;
}
