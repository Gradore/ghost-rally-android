extends RefCounted
# Spatial branch clusters using licensed photographed needles, not full-tree billboards.
static func mesh() -> ArrayMesh:
	var trunk := SurfaceTool.new();trunk.begin(Mesh.PRIMITIVE_TRIANGLES)
	var foliage := SurfaceTool.new();foliage.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new();rng.seed=4817
	for tier in 10:
		var y := 1.1+tier*0.66
		var span := (1.0-float(tier)/12)*2.0
		for branch in 6:
			var angle := branch*TAU/6+tier*0.61+rng.randf_range(-0.2,0.2)
			var along := Vector3(cos(angle),0,sin(angle));var side := Vector3(-sin(angle),0,cos(angle))
			var base := Vector3(0,y,0);var tip := base+along*span+Vector3.UP*0.14
			for face in 3:
				var a := base+side*(0.045 if face==0 else -0.045)
				var b := tip+Vector3.UP*0.012
				triangle(trunk,a,b,base+Vector3.UP*0.065,Vector2.ZERO,Vector2(1,1),Vector2(0,1))
			for leaf in 4:
				var pos := base+along*span*(0.22+leaf*0.23)+side*rng.randf_range(-0.12,0.12)
				var cross_side := side*(0.50 if leaf<3 else 0.30)
				var axis := along*(0.38 if leaf<3 else 0.25)+Vector3.UP*0.18
				quad(foliage,pos,cross_side,axis)
				quad(foliage,pos,cross_side*0.72,Vector3.UP*0.45)
	# Tapered trunk with a buried root foot.
	for i in 8:
		var a := float(i)*TAU/8;var b := float(i+1)*TAU/8
		var lo := Vector3(cos(a)*0.15,-0.18,sin(a)*0.15);var ro := Vector3(cos(b)*0.15,-0.18,sin(b)*0.15)
		var hi := Vector3(cos(a)*0.015,8.2,sin(a)*0.015);var rh := Vector3(cos(b)*0.015,8.2,sin(b)*0.015)
		triangle(trunk,lo,hi,ro,Vector2(0,0),Vector2(0,4),Vector2(1,0));triangle(trunk,ro,hi,rh,Vector2(1,0),Vector2(0,4),Vector2(1,4))
	trunk.generate_normals();trunk.generate_tangents();var result := trunk.commit()
	foliage.generate_normals();foliage.generate_tangents();foliage.commit(result)
	var bark := StandardMaterial3D.new();bark.albedo_texture=load("res://assets/nature/bark_diff.jpg");bark.roughness=0.92
	result.surface_set_material(0,bark)
	var needles := ShaderMaterial.new();needles.shader=load("res://assets/shaders/pine_foliage.gdshader")
	needles.set_shader_parameter("diffuse_tex",load("res://assets/nature/twig_diff.jpg"));needles.set_shader_parameter("alpha_tex",load("res://assets/nature/twig_alpha.png"));needles.set_shader_parameter("normal_tex",load("res://assets/nature/twig_nor_gl.png"))
	result.surface_set_material(1,needles)
	return result
static func triangle(s: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,ua: Vector2,ub: Vector2,uc: Vector2) -> void:
	for pair in [[a,ua],[b,ub],[c,uc]]:s.set_uv(pair[1]);s.add_vertex(pair[0])
static func quad(s: SurfaceTool,p: Vector3,right: Vector3,up: Vector3) -> void:
	triangle(s,p-right-up,p-right+up,p+right-up,Vector2(0.01,0.45),Vector2(0.01,0.0),Vector2(0.23,0.45))
	triangle(s,p+right-up,p-right+up,p+right+up,Vector2(0.23,0.45),Vector2(0.01,0.0),Vector2(0.23,0.0))
static func plant(parent: Node3D,transforms: Array[Transform3D]) -> void:
	var chunks := {}
	for t in transforms:
		var key := Vector2i(floori(t.origin.x/128),floori(t.origin.z/128))
		if not chunks.has(key):chunks[key]=[]
		chunks[key].append(t)
	var tree := mesh()
	for key in chunks:
		var node := MultiMeshInstance3D.new();node.name="SpatialPines";node.add_to_group("spatial_pines")
		node.position=Vector3((key.x+0.5)*128,0,(key.y+0.5)*128)
		node.multimesh=MultiMesh.new();node.multimesh.transform_format=MultiMesh.TRANSFORM_3D;node.multimesh.mesh=tree
		node.multimesh.instance_count=chunks[key].size()
		var roots := PackedVector3Array()
		for t in chunks[key]:roots.append(t.origin)
		node.set_meta("ground_roots",roots)
		for i in chunks[key].size():
			var t: Transform3D=chunks[key][i];t.origin-=node.position;node.multimesh.set_instance_transform(i,t)
		node.visibility_range_end=185;node.visibility_range_end_margin=12
		parent.add_child(node)
