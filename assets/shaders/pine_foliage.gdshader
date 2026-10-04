shader_type spatial;
render_mode cull_disabled, alpha_to_coverage;
uniform sampler2D diffuse_tex : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D alpha_tex : filter_linear_mipmap;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic;
void vertex() {
 VERTEX.x += sin(TIME*1.5+VERTEX.y*1.1+MODEL_MATRIX[3].x)*0.018*max(VERTEX.y-1.0,0.0);
}
void fragment() {
 ALBEDO=texture(diffuse_tex,UV).rgb*vec3(0.82,0.92,0.74);
 ALPHA=texture(alpha_tex,UV).r;
 ALPHA_SCISSOR_THRESHOLD=0.44;
 ALPHA_ANTIALIASING_EDGE=0.22;
 ALPHA_TEXTURE_COORDINATE=UV*vec2(textureSize(alpha_tex,0));
 NORMAL_MAP=texture(normal_tex,UV).rgb;
 NORMAL_MAP_DEPTH=0.55;
 ROUGHNESS=0.85;
}
