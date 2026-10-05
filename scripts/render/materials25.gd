extends RefCounted
# Synthetic photo-style albedo, bounded shared material cache. No Google pixels.
static var cache := {}
static func surface(kind: int, tint: Color=Color.WHITE, vertex_tint: bool=false) -> ShaderMaterial:
	var key := str(kind)+str(tint)+str(vertex_tint)
	if cache.has(key):return cache[key]
	var m := ShaderMaterial.new();m.shader=preload("res://assets/shaders/material25.gdshader")
	m.set_shader_parameter("atlas",load("res://assets/textures/material_atlas25.png"))
	if kind in [1,2,6]:
		m.shader=preload("res://assets/shaders/facade27.gdshader")
		for pair in [["brick","Bricks001"],["plaster","Plaster002"]]:
			for map in [["color","Color"],["normal","NormalGL"],["rough","Roughness"]]:
				m.set_shader_parameter(pair[0]+"_"+map[0],load("res://assets/textures/facades27/"+pair[1]+"_1K-JPG_"+map[1]+".jpg"))
	m.set_shader_parameter("kind",kind);m.set_shader_parameter("tint",tint);m.set_shader_parameter("vertex_tint",vertex_tint)
	cache[key]=m;return m
