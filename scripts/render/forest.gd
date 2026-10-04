extends RefCounted
# Spatial branch clusters using licensed photographed needles, not full-tree billboards.
static func mesh() -> ArrayMesh:
	var trunk := SurfaceTool.new();trunk.begin(Mesh.PRIMITIVE_TRIANGLES)
	var foliage := SurfaceTool.new();foliage.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new();rng.seed=4817
	for tier in 12:
		var y := 1.1+tier*0.57
		var span := (1.0-float(tier)/13)*2.0
		for branch in 6:
			var angle := branch*TAU/6+tier*0.61+rng.randf_range(-0.2,0.2)
			var along := Vector3(cos(angle),0,sin(angle));var side := Vector3(-sin(angle),0,cos(angle))
			var base := Vector3(0,y,0);var tip := base+along*span+Vector3.UP*0.14
			for face in 11:
				var a := base+side*(0.045 if face==0 else -0.045)
				var b := tip+Vector3.UP*0.012
				triangle(trunk,a,b,base+Vector3.UP*0.065,Vector2.ZERO,Vector2(1,1),Vector2(0,1))
			for leaf in 5:
				var pos := base+along*span*(0.14+leaf*0.19)+side*rng.randf_range(-0.12,0.12)
				var cross_side := side*(0.62 if leaf<3 else 0.38)
				var axis := along*(0.50 if leaf<3 else 0.32)+Vector3.UP*0.18
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
	plant_mesh(parent,transforms,mesh(),"spatial_pines",185)
static func plant_mesh(parent: Node3D,transforms: Array[Transform3D],tree: Mesh,group: String,distance: float,begin_distance: float=0.0) -> void:
	var chunks := {}
	var chunk_size := 32.0 if group=="verge_grass" else 128.0
	for t in transforms:
		var key := Vector2i(floori(t.origin.x/chunk_size),floori(t.origin.z/chunk_size))
		if not chunks.has(key):chunks[key]=[]
		chunks[key].append(t)
	for key in chunks:
		var node := MultiMeshInstance3D.new();node.name=group;node.add_to_group(group)
		node.position=Vector3((key.x+0.5)*chunk_size,0,(key.y+0.5)*chunk_size)
		node.multimesh=MultiMesh.new();node.multimesh.transform_format=MultiMesh.TRANSFORM_3D;node.multimesh.mesh=tree
		node.multimesh.instance_count=chunks[key].size()
		var roots := PackedVector3Array()
		for t in chunks[key]:roots.append(t.origin)
		node.set_meta("ground_roots",roots)
		for i in chunks[key].size():
			var t: Transform3D=chunks[key][i];t.origin-=node.position;node.multimesh.set_instance_transform(i,t)
		node.visibility_range_begin=begin_distance;node.visibility_range_begin_margin=8
		node.visibility_range_end=distance;node.visibility_range_end_margin=12
		parent.add_child(node)

static func broadleaf_mesh() -> ArrayMesh:
	var wood := SurfaceTool.new();wood.begin(Mesh.PRIMITIVE_TRIANGLES)
	var leaves := SurfaceTool.new();leaves.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new();rng.seed=6701
	# Closed trunk and radial branch tubes, followed by spatial crown clusters.
	tube(wood,Vector3(0,-0.18,0),Vector3(0,4.7,0),0.23,0.07)
	for branch in 9:
		var angle := branch*2.39996
		var start := Vector3(0,2.4+branch*0.21,0)
		var end := start+Vector3(cos(angle)*2.0,1.45,sin(angle)*2.0)
		tube(wood,start,end,0.095,0.025)
		for cluster in 5:
			var center := end+Vector3(rng.randf_range(-0.7,0.7),rng.randf_range(-0.15,1.5),rng.randf_range(-0.7,0.7))
			for face in 11:
				var a := rng.randf_range(-PI,PI)
				var right := Vector3(cos(a),0,sin(a))*rng.randf_range(0.36,0.62)
				var up := Vector3(-sin(a)*0.15,0.45,cos(a)*0.15)
				if face%3==2:up=Vector3(-sin(a),0.15,cos(a))*0.5
				var leaf_center := center+Vector3(rng.randf_range(-0.8,0.8),rng.randf_range(-0.5,0.65),rng.randf_range(-0.8,0.8))
				var tint := Color(rng.randf_range(0.83,1.07),rng.randf_range(0.9,1.1),rng.randf_range(0.8,1.0))
				var uv0 := Vector2(rng.randf_range(0.08,0.55),rng.randf_range(0.08,0.34))
				for pair in [[leaf_center-right-up,Vector2(0,1)],[leaf_center-right+up,Vector2(0,0)],[leaf_center+right-up,Vector2(1,1)],[leaf_center+right-up,Vector2(1,1)],[leaf_center-right+up,Vector2(0,0)],[leaf_center+right+up,Vector2(1,0)]]:
					leaves.set_color(tint);leaves.set_uv(uv0+pair[1]*Vector2(0.24,0.24));leaves.set_uv2(pair[1]);leaves.add_vertex(pair[0])
	wood.generate_normals();wood.generate_tangents();var result := wood.commit()
	leaves.generate_normals();leaves.commit(result)
	var bark := StandardMaterial3D.new();bark.albedo_texture=load("res://assets/nature/bark_diff.jpg");bark.albedo_color=Color(0.65,0.62,0.55);bark.roughness=0.95
	result.surface_set_material(0,bark)
	var leaf_mat := ShaderMaterial.new();leaf_mat.shader=load("res://assets/shaders/broadleaf.gdshader");leaf_mat.set_shader_parameter("leaf_tex",load("res://assets/textures/oak_v10.png"));result.surface_set_material(1,leaf_mat)
	return result

static func tube(s: SurfaceTool,a: Vector3,b: Vector3,r0: float,r1: float) -> void:
	var axis := (b-a).normalized()
	var right := axis.cross(Vector3.FORWARD).normalized()
	var up := axis.cross(right).normalized()
	for i in 7:
		var c := float(i)*TAU/7;var d := float(i+1)*TAU/7
		var lo := a+(right*cos(c)+up*sin(c))*r0;var ro := a+(right*cos(d)+up*sin(d))*r0
		var hi := b+(right*cos(c)+up*sin(c))*r1;var rh := b+(right*cos(d)+up*sin(d))*r1
		triangle(s,lo,hi,ro,Vector2(i/7.0,0),Vector2(i/7.0,2),Vector2((i+1)/7.0,0))
		triangle(s,ro,hi,rh,Vector2((i+1)/7.0,0),Vector2(i/7.0,2),Vector2((i+1)/7.0,2))
