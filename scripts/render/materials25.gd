extends RefCounted
# Synthetic photo-style albedo, bounded shared material cache. No Google pixels.
static var cache := {}
static func surface(kind: int, tint: Color=Color.WHITE, vertex_tint: bool=false) -> ShaderMaterial:
	var key := str(kind)+str(tint)+str(vertex_tint)
	if cache.has(key):return cache[key]
	var m := ShaderMaterial.new();m.shader=preload("res://assets/shaders/material25.gdshader")
	m.set_shader_parameter("atlas",load("res://assets/textures/material_atlas25.png"))
	m.set_shader_parameter("kind",kind);m.set_shader_parameter("tint",tint);m.set_shader_parameter("vertex_tint",vertex_tint)
	cache[key]=m;return m
