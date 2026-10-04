extends RefCounted
static var geometry_cache := {}
# Spatial branch clusters using licensed photographed needles, not full-tree billboards.
static func mesh(variant: int=0, low_detail: bool=false) -> ArrayMesh:
	var cache_key := "pine"+str(variant)+str(low_detail)
	if geometry_cache.has(cache_key):return geometry_cache[cache_key]
	var trunk := SurfaceTool.new();trunk.begin(Mesh.PRIMITIVE_TRIANGLES)
	var foliage := SurfaceTool.new();foliage.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new();rng.seed=4817+variant*973
	# Irregular ascending branches: two open-crowned pines and a fuller conifer.
	tube(trunk,Vector3(0,-0.18,0),Vector3(0.10,5.0,-0.08),0.16,0.065)
	tube(trunk,Vector3(0.10,5.0,-0.08),Vector3(-0.05,8.2,0.06),0.065,0.008)
	var branches := 15 if low_detail else 27
	for branch in branches:
		var fraction := float(branch)/float(branches-1)
		var low := 1.4 if variant==2 else 3.1
		var y := lerpf(low,7.95,fraction)+rng.randf_range(-0.25,0.22)
		var span := (2.5*(1.0-fraction*0.80) if variant==2 else 1.5+sin(fraction*PI)*1.0-fraction*0.85)*rng.randf_range(0.72,1.18)
		var angle := branch*2.39996+rng.randf_range(-0.38,0.38)
		var along := Vector3(cos(angle),0,sin(angle));var side := Vector3(-sin(angle),0,cos(angle))
		var base := Vector3(0.08,y,0)
		var elbow := base+along*span*0.52+Vector3.UP*rng.randf_range(-0.18,0.15)
		var tip := base+along*span+Vector3.UP*rng.randf_range(0.22,0.60)
		if not low_detail:
			tube(trunk,base,elbow,0.045,0.026);tube(trunk,elbow,tip,0.026,0.009)
		var twigs := 3 if low_detail else 5
		for twig in twigs:
			var center := elbow.lerp(tip,float(twig)/maxf(twigs-1,1))+side*rng.randf_range(-0.35,0.35)
			for sprig in (3 if low_detail else 4):
				var yaw := angle+rng.randf_range(-1.4,1.4)
				var right := Vector3(-sin(yaw),0,cos(yaw))*rng.randf_range(0.17,0.29)
				var up := Vector3(cos(yaw)*0.22,0.46,sin(yaw)*0.22)*rng.randf_range(0.85,1.35)
				var pos := center+Vector3(rng.randf_range(-0.38,0.38),rng.randf_range(-0.10,0.32),rng.randf_range(-0.38,0.38))
				quad(foliage,pos,right,up)
				if not low_detail and sprig%2==0:quad(foliage,pos,Vector3(up.x,0.12,up.z)+along*0.20,right+Vector3.UP*0.16)
	trunk.generate_normals();trunk.generate_tangents();var result := trunk.commit()
	foliage.generate_normals();foliage.generate_tangents();foliage.commit(result)
	var bark := StandardMaterial3D.new();bark.albedo_texture=load("res://assets/nature/bark_diff.jpg");bark.roughness=0.92
	result.surface_set_material(0,bark)
	var needles := ShaderMaterial.new();needles.shader=load("res://assets/shaders/pine_foliage.gdshader")
	needles.set_shader_parameter("diffuse_tex",load("res://assets/nature/twig_diff.jpg"));needles.set_shader_parameter("alpha_tex",load("res://assets/nature/twig_alpha.png"));needles.set_shader_parameter("normal_tex",load("res://assets/nature/twig_nor_gl.png"))
	result.surface_set_material(1,needles)
	geometry_cache[cache_key]=result
	return result
static func triangle(s: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,ua: Vector2,ub: Vector2,uc: Vector2) -> void:
	for pair in [[a,ua],[b,ub],[c,uc]]:s.set_uv(pair[1]);s.add_vertex(pair[0])
static func quad(s: SurfaceTool,p: Vector3,right: Vector3,up: Vector3) -> void:
	triangle(s,p-right-up,p-right+up,p+right-up,Vector2(0.01,0.45),Vector2(0.01,0.0),Vector2(0.23,0.45))
	triangle(s,p+right-up,p-right+up,p+right+up,Vector2(0.23,0.45),Vector2(0.01,0.0),Vector2(0.23,0.0))
static func plant(parent: Node3D,transforms: Array[Transform3D]) -> void:
	plant_variants(parent,transforms,"spatial_pines",175,0.0,false,false)
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

static func plant_variants(parent: Node3D, transforms: Array[Transform3D], group: String, distance: float, begin_distance: float, deciduous: bool, low_detail: bool) -> void:
	var variants := [[],[],[]]
	for i in transforms.size():variants[i%3].append(transforms[i])
	for variant in 3:
		var geometry := broadleaf_mesh(variant,low_detail) if deciduous else mesh(variant,low_detail)
		var subset: Array[Transform3D]=[];subset.assign(variants[variant])
		plant_mesh(parent,subset,geometry,group,distance,begin_distance)

static func broadleaf_mesh(variant: int=0, low_detail: bool=false) -> ArrayMesh:
	var cache_key := "oak"+str(variant)+str(low_detail)
	if geometry_cache.has(cache_key):return geometry_cache[cache_key]
	var wood := SurfaceTool.new();wood.begin(Mesh.PRIMITIVE_TRIANGLES)
	var leaves := SurfaceTool.new();leaves.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new();rng.seed=6701+variant*1709
	# Closed trunk and radial branch tubes, followed by spatial crown clusters.
	tube(wood,Vector3(0,-0.18,0),Vector3(0,4.7,0),0.23,0.07)
	for branch in 9:
		var angle := branch*2.39996
		var start := Vector3(0,2.4+branch*0.21,0)
		var end := start+Vector3(cos(angle)*rng.randf_range(1.6,2.4),rng.randf_range(1.1,1.9),sin(angle)*rng.randf_range(1.6,2.4))
		tube(wood,start,end,0.095,0.025)
		for cluster in (3 if low_detail else 4):
			var center := end+Vector3(rng.randf_range(-0.7,0.7),rng.randf_range(-0.15,1.5),rng.randf_range(-0.7,0.7))
			for face in (14 if low_detail else 52):
				var a := rng.randf_range(-PI,PI)
				var right := Vector3(cos(a),0,sin(a))*(rng.randf_range(0.27,0.39) if low_detail else rng.randf_range(0.12,0.23))
				var up := Vector3(-sin(a)*0.08,0.32 if low_detail else rng.randf_range(0.18,0.29),cos(a)*0.08)
				if face%3==2:up=Vector3(-sin(a),0.08,cos(a))*(0.30 if low_detail else 0.20)
				var leaf_center := center+Vector3(rng.randf_range(-1.1,1.1),rng.randf_range(-0.65,0.8),rng.randf_range(-1.1,1.1))
				var shade := lerpf(0.65,1.05,clampf((leaf_center.y-3.0)/4.0,0,1))
				var tint := Color(rng.randf_range(0.83,1.07),rng.randf_range(0.9,1.1),rng.randf_range(0.8,1.0))*shade
				var uv0 := Vector2(rng.randf_range(0.08,0.55),rng.randf_range(0.08,0.34))
				for pair in [[leaf_center-right-up,Vector2(0,1)],[leaf_center-right+up,Vector2(0,0)],[leaf_center+right-up,Vector2(1,1)],[leaf_center+right-up,Vector2(1,1)],[leaf_center-right+up,Vector2(0,0)],[leaf_center+right+up,Vector2(1,0)]]:
					leaves.set_normal((pair[0]-Vector3(0,4.4,0)).normalized());leaves.set_color(tint);leaves.set_uv(uv0+pair[1]*Vector2(0.24,0.24));leaves.set_uv2(pair[1]);leaves.add_vertex(pair[0])
	wood.generate_normals();wood.generate_tangents();var result := wood.commit()
	leaves.commit(result)
	var bark := StandardMaterial3D.new();bark.albedo_texture=load("res://assets/nature/bark_diff.jpg");bark.albedo_color=Color(0.65,0.62,0.55);bark.roughness=0.95
	result.surface_set_material(0,bark)
	var leaf_mat := ShaderMaterial.new();leaf_mat.shader=load("res://assets/shaders/broadleaf.gdshader");leaf_mat.set_shader_parameter("leaf_tex",load("res://assets/textures/oak_v10.png"));result.surface_set_material(1,leaf_mat)
	geometry_cache[cache_key]=result
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
