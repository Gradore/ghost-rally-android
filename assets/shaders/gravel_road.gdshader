shader_type spatial;
render_mode cull_disabled;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float road_half_width = 3.0;
float hash(vec2 p) {return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p) {vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void fragment() {
 float across = UV.x * 4.0;
 float along = UV.y * 4.0;
 float drift = sin(along * 0.039) * 0.08 + sin(along * 0.13) * 0.025;
 float rut = exp(-pow((abs(across + drift) - 0.82) / 0.36, 2.0));
 float edge = smoothstep(road_half_width - 0.8, road_half_width + 0.05, abs(across));
 vec3 detail = texture(albedo_tex, UV * 1.65).rgb;
 vec3 macro = texture(albedo_tex, UV * 0.11 + vec2(0.23, 0.47)).rgb;
 ALBEDO = detail * mix(vec3(0.84,0.80,0.72), vec3(0.69,0.66,0.59), rut * 0.70);
 ALBEDO *= mix(0.9, 1.1, macro.r);
 // Broad mineral patches interrupt visible texture repetition without changing grip.
 float patch = noise(vec2(across*0.43,along*0.19));
 float fine_patch = noise(vec2(across*1.1,along*0.63)+vec2(7.0,13.0));
 ALBEDO *= mix(vec3(0.83,0.88,0.90),vec3(1.03,0.96,0.84),patch);
 ALBEDO *= mix(0.92,1.04,fine_patch);
 ALBEDO *= mix(vec3(1.0),vec3(0.77,0.79,0.65),edge*0.45);
 NORMAL_MAP = texture(normal_tex, UV * 1.65).rgb;
 NORMAL_MAP_DEPTH = 0.85;
 ROUGHNESS = mix(0.96,0.88,rut);
}
