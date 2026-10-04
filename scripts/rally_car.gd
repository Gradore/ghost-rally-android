extends CharacterBody3D
class_name RallyCar

var body: Node3D
var wheels: Array[Node3D] = []
var wheel_spins: Array[Node3D] = [null,null,null,null]
var material: StandardMaterial3D
var ghost := false
var rear_lamps: StandardMaterial3D
var dust: GPUParticles3D

func _mat(color: Color, rough: float = 0.65, metallic: float = 0.0, transparent: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metallic
	if transparent:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = mat
	instance.position = pos
	parent.add_child(instance)
	return instance

func _loft(parent: Node3D, rings: Array, mat: Material) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for i in range(rings.size()-1):
		for j in rings[i].size():
			var next: int = (j+1)%rings[i].size()
			for vertex in [rings[i][j],rings[i][next],rings[i+1][j],rings[i][next],rings[i+1][next],rings[i+1][j]]:
				surface.add_vertex(vertex)
	for end in [0,rings.size()-1]:
		var center := Vector3.ZERO
		for vertex in rings[end]: center+=vertex
		center/=float(rings[end].size())
		for j in rings[end].size():
			var edge_a: Vector3=rings[end][j]
			var edge_b: Vector3=rings[end][(j+1)%rings[end].size()]
			for vertex in [center,edge_a,edge_b] if end>0 else [center,edge_b,edge_a]:surface.add_vertex(vertex)
	surface.generate_normals()
	var instance := MeshInstance3D.new()
	instance.mesh=surface.commit()
	instance.material_override=mat
	parent.add_child(instance)

func configure(car: Dictionary, as_ghost: bool = false, livery: int = 0) -> void:
	ghost=as_ghost
	collision_layer=0 if ghost else 2
	collision_mask=0 if ghost else 1
	body=Node3D.new()
	add_child(body)
	var voc: bool=car.get("voc",false)
	var paint: Color=car.color
	if livery==1:paint=Color("f4f5e8")
	if livery==2:paint=Color("1b2638")
	if ghost:paint=Color(0.34,0.94,0.91,0.34)
	material=_mat(paint,0.28,0.25,ghost)
	material.clearcoat_enabled=not ghost
	material.clearcoat=0.80
	material.clearcoat_roughness=0.26
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	var body_paint: Material=material
	if not ghost:
		var paint_shader := ShaderMaterial.new();paint_shader.shader=load("res://assets/shaders/rally_paint.gdshader")
		paint_shader.set_shader_parameter("paint_color",paint);body_paint=paint_shader
	rear_lamps=_mat(Color("a82015"),0.24,0.08,ghost)
	rear_lamps.emission_enabled=not ghost;rear_lamps.emission=Color("ed2814");rear_lamps.emission_energy_multiplier=0.02
	var trim := _mat(Color(0.1,0.16,0.18,0.3) if ghost else Color("12171b"),0.8,0.05,ghost)
	var glass := _mat(Color(0.15,0.35,0.45,0.3) if ghost else Color("263a44"),0.42,0.0,ghost)
	glass.metallic=0.32
	glass.roughness=0.10
	glass.clearcoat_enabled=not ghost;glass.clearcoat=0.95;glass.clearcoat_roughness=0.08
	glass.cull_mode=BaseMaterial3D.CULL_DISABLED
	var chrome := _mat(Color("aeb6ba"),0.2,0.85,ghost)
	var length := 4.87 if voc else (3.95 if car.drive=="FWD" else 4.40)
	var width := 1.75 if voc else (1.82 if car.drive=="FWD" else 1.88)
	var wheelbase: float=car.get("wheelbase",2.60)
	var radius: float=car.get("wheel_radius",0.32)
	if not ghost:
		var shape := BoxShape3D.new()
		shape.size=Vector3(width,1.28,length*0.94)
		var hitbox := CollisionShape3D.new()
		hitbox.shape=shape;hitbox.position=Vector3(0,0.82,0)
		add_child(hitbox)
	var rings := []
	var stations := [-length*0.5,-length*0.46,-0.30,0.35,length*0.46,length*0.5]
	for axle in [-1.0,1.0]:
		for step in range(-5,6):stations.append(axle*wheelbase*0.5+float(step)*radius*1.12/5.0)
	stations.sort()
	for z_value in stations:
		var fraction: float=z_value/length
		var z: float=fraction*length
		var half: float=width*0.5*(0.90 if absf(fraction)>0.45 else 1.0)
		var top := 0.90 if voc else 0.87
		var bottom := 0.30
		# Raised side sill around the wheel centers forms the wheel openings.
		var wheel_distance := absf(absf(z)-wheelbase*0.5)
		if wheel_distance<radius*1.12:bottom=radius+sqrt(maxf(0,pow(radius*1.12,2)-wheel_distance*wheel_distance))
		rings.append([Vector3(-half*0.94,bottom,z),Vector3(-half,bottom+0.08,z),Vector3(-half,top-0.09,z),Vector3(-half*0.92,top,z),Vector3(half*0.92,top,z),Vector3(half,top-0.09,z),Vector3(half,bottom+0.08,z),Vector3(half*0.94,bottom,z)])
	_loft(body,rings,body_paint)
	var cabin := []
	for spec in [[-0.82,0.91,width*0.43],[-0.28,1.44,width*0.36],[0.83,1.44,width*0.36],[1.38,0.94,width*0.43]]:
		var z: float=spec[0] if voc else float(spec[0])*0.86
		var y: float=spec[1]
		var half: float=spec[2]
		cabin.append([Vector3(-half,0.90,z),Vector3(-half,y,z),Vector3(half,y,z),Vector3(half,0.90,z)])
	_loft(body,cabin,glass)
	_box(body,Vector3(width*0.73,0.07,1.15),Vector3(0,1.47,0.27),material)
	for side in [-1.0,1.0]:
		for spec in [[-0.82,0.91,-0.28,1.44],[0.83,1.44,1.38,0.94]]:
			var factor := 1.0 if voc else 0.86
			var start := Vector3(side*width*0.405,spec[1],spec[0]*factor)
			var end := Vector3(side*width*0.365,spec[3],spec[2]*factor)
			var pillar := _box(body,Vector3(0.075,start.distance_to(end),0.075),(start+end)*0.5,material)
			pillar.rotation.x=atan2(end.z-start.z,end.y-start.y)
		_box(body,Vector3(0.055,0.51,0.09),Vector3(side*width*0.385,1.17,0.38),trim)
		_box(body,Vector3(0.14,0.055,0.06),Vector3(side*width*0.51,0.82,0.34),chrome)
		_box(body,Vector3(0.14,0.055,0.06),Vector3(side*width*0.51,0.82,0.94),chrome)
		_box(body,Vector3(0.065,0.045,length*0.86),Vector3(side*width*0.51,0.61,0),trim)
		_box(body,Vector3(0.20,0.14,0.29),Vector3(side*(width*0.5+0.07),1.02,-0.63),material)
		for end in [-1.0,1.0]:
			var pivot := Node3D.new()
			pivot.position=Vector3(side*(width*0.5-0.04),radius,end*wheelbase*0.5)
			body.add_child(pivot)
			var spin := Node3D.new();pivot.add_child(spin)
			wheel_spins[(0 if end<0 else 2)+(0 if side<0 else 1)]=spin
			_build_wheel(spin,radius,0.195 if voc else 0.235,ghost)
			if end<0:wheels.append(pivot)
		var number := Label3D.new()
		number.text="69" if voc else "27"
		number.font_size=80;number.pixel_size=0.006
		number.position=Vector3(side*(width*0.5+0.008),0.79,0.05)
		number.rotation.y=side*PI/2
		number.modulate=Color("f4f1d9")
		body.add_child(number)
	_box(body,Vector3(width*0.91,0.16,0.14),Vector3(0,0.51,-length*0.5),trim)
	_box(body,Vector3(width*0.91,0.16,0.14),Vector3(0,0.51,length*0.5),trim)
	_box(body,Vector3(0.65,0.21,0.04),Vector3(0,0.74,-length*0.5-0.01),trim)
	# Fictional vertical grille, without the original manufacturer's diagonal badge.
	for bar in 7:
		_box(body,Vector3(0.018,0.17,0.022),Vector3((bar-3)*0.075,0.74,-length*0.5-0.04),chrome)
	for side in [-1.0,1.0]:
		_box(body,Vector3(0.38,0.17,0.03),Vector3(side*width*0.35,0.75,-length*0.5-0.025),_mat(Color("f5edd5"),0.18,0.1,ghost))
		if not voc:_box(body,Vector3(0.26,0.19,0.03),Vector3(side*width*0.36,0.77,length*0.5+0.025),rear_lamps)
	if not voc and car.drive=="AWD":
		_box(body,Vector3(width*0.86,0.07,0.24),Vector3(0,1.16,length*0.44),material)
		for side in [-1.0,1.0]:_box(body,Vector3(0.045,0.28,0.10),Vector3(side*width*0.31,1.03,length*0.44),trim)

	if voc:
		_box(body,Vector3(0.46,0.105,0.025),Vector3(0,0.74,length*0.5+0.04),_mat(Color("e4e1cd")))
		var badge := Label3D.new();badge.text="LOVO 940";badge.font_size=22;badge.pixel_size=0.0035
		badge.position=Vector3(-0.43,0.88,length*0.5+0.04);badge.rotation.y=0;body.add_child(badge)
		for side in [-1.0,1.0]:
			_box(body,Vector3(0.19,0.34,0.042),Vector3(side*width*0.42,0.72,length*0.5+0.035),trim)
			for part in 4:
				var lens: Material=rear_lamps if part in [0,3] else _mat(Color("c8b9a0") if part==1 else Color("b37422"),0.25)
				_box(body,Vector3(0.16,0.072,0.012),Vector3(side*width*0.42,0.60+part*0.081,length*0.5+0.062),lens)
			for z in [-0.65,0.35,1.0]:_box(body,Vector3(0.013,0.22,0.018),Vector3(side*width*0.504,0.78,z),trim)
	if not ghost:
		# Body seams, wiper, exhaust and rally mudflaps enrich the authored mesh.
		for side in [-1.0,1.0]:
			_box(body,Vector3(0.015,0.012,1.18),Vector3(side*width*0.35,1.512,0.26),trim)
			for axle in [-1.0,1.0]:
				_box(body,Vector3(0.22,0.30,0.018),Vector3(side*(width*0.5-0.04),0.26,axle*wheelbase*0.5+0.31),trim)
		_box(body,Vector3(width*0.69,0.012,0.008),Vector3(0,1.12,1.17 if voc else 1.0),trim)
		_box(body,Vector3(0.012,0.014,0.43),Vector3(-0.24,1.13,1.20 if voc else 1.03),trim)
		var pipe := CylinderMesh.new();pipe.top_radius=0.037;pipe.bottom_radius=0.037;pipe.height=0.20;pipe.radial_segments=12
		var exhaust := MeshInstance3D.new();exhaust.mesh=pipe;exhaust.material_override=chrome
		exhaust.rotation.x=PI/2;exhaust.position=Vector3(-width*0.31,0.33,length*0.5);body.add_child(exhaust)
	if not ghost:
		var plate := Label3D.new();plate.text="LOVO · 69" if voc else "GHOST · 27";plate.font_size=40;plate.pixel_size=0.0015
		plate.modulate=Color("17221f");plate.position=Vector3(0,0.735,length*0.5+0.057);body.add_child(plate)
		# Rear glass heating wires and trunk gaps catch close chase-camera views.
		for wire in 7:
			var f := float(wire)/8.0
			_box(body,Vector3(width*0.64,0.0024,0.0024),Vector3(0,1.39-f*0.36,0.90+f*0.39),_mat(Color("283a32"),0.85))
		_box(body,Vector3(width*0.86,0.008,0.009),Vector3(0,0.91,length*0.44),trim)
	_merge_static_body()
	build_dust()

func set_braking(enabled: bool) -> void:
	if rear_lamps!=null and not ghost:rear_lamps.emission_energy_multiplier=0.85 if enabled else 0.02

func animate_car(steer: float, slip: float, speed: float, delta: float) -> void:
	for wheel in wheels:wheel.rotation.y=lerpf(wheel.rotation.y,-steer*0.45/(1.0+speed*0.018),minf(1.0,delta*10.0))


func build_dust() -> void:
	if ghost:return
	dust=GPUParticles3D.new();dust.amount=140;dust.lifetime=1.4;dust.emitting=false
	dust.local_coords=false;dust.position=Vector3(0,0.22,1.35)
	var process := ParticleProcessMaterial.new();process.direction=Vector3(0,0.4,1)
	process.spread=35;process.initial_velocity_min=0.6;process.initial_velocity_max=3.2
	process.gravity=Vector3(0,0.15,0);process.scale_min=0.18;process.scale_max=0.7
	var gradient := Gradient.new();gradient.set_color(0,Color(0.55,0.45,0.31,0.22));gradient.set_color(1,Color(0.6,0.51,0.39,0))
	var ramp := GradientTexture1D.new();ramp.gradient=gradient;process.color_ramp=ramp
	process.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents=Vector3(0.72,0.02,0.18)
	dust.visibility_aabb=AABB(Vector3(-8,-2,-8),Vector3(16,8,20))
	dust.process_material=process
	var quad := QuadMesh.new();quad.size=Vector2(1.3,1.3)
	var m := StandardMaterial3D.new();m.albedo_color=Color.WHITE;m.vertex_color_use_as_albedo=true
	m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;m.billboard_mode=BaseMaterial3D.BILLBOARD_PARTICLES
	var cloud := Image.create(32,32,false,Image.FORMAT_RGBA8)
	for py in 32:
		for px in 32:
			var distance := Vector2(float(px)-15.5,float(py)-15.5).length()/15.5
			cloud.set_pixel(px,py,Color(1,1,1,pow(maxf(0,1-distance),2)))
	m.albedo_texture=ImageTexture.create_from_image(cloud)
	m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;m.disable_receive_shadows=true
	quad.material=m;dust.draw_pass_1=quad;add_child(dust)

func update_dust(enabled: bool,speed_mps: float) -> void:
	if dust==null:return
	dust.emitting=enabled and speed_mps>5
	dust.amount_ratio=clampf(speed_mps/30.0,0.15,1.0)

func update_wheel_visuals(states: Array) -> void:
	for i in mini(4,states.size()):
		if wheel_spins[i]!=null:wheel_spins[i].rotation.x=-float(states[i].spin)

func update_suspension_visuals(sim: RefCounted) -> void:
	if not sim.initialized:return
	body.rotation.x=sim.pitch;body.rotation.z=sim.roll
	for i in 4:
		if wheel_spins[i]==null:continue
		var hub: Dictionary=sim.hubs[i]
		var pivot: Node3D=wheel_spins[i].get_parent()
		pivot.position.y=float(hub.y)-sim.height+sim.ride_height-sim.pitch*float(hub.z)-sim.roll*float(hub.x)

func _merge_static_body() -> void:
	_merge_meshes(body)

func _merge_meshes(parent: Node3D) -> void:
	# Static panels share mesh submissions; articulated wheels and labels stay separate.
	var batches := {}
	var old_nodes: Array[MeshInstance3D]=[]
	for node in parent.get_children():
		if not node is MeshInstance3D:continue
		old_nodes.append(node)
		for surface in node.mesh.get_surface_count():
			var mat: Material=node.material_override if node.material_override!=null else node.mesh.surface_get_material(surface)
			if not batches.has(mat):
				var builder := SurfaceTool.new();builder.begin(Mesh.PRIMITIVE_TRIANGLES);batches[mat]=builder
			batches[mat].append_from(node.mesh,surface,node.transform)
	for node in old_nodes:parent.remove_child(node);node.queue_free()
	for mat in batches:
		var node := MeshInstance3D.new();node.mesh=batches[mat].commit();node.material_override=mat;parent.add_child(node)

func _build_wheel(spin: Node3D, radius: float, width: float, transparent: bool) -> void:
	# A rounded shoulder and recessed spoke face replace the flat cylinder silhouette.
	var rubber: Material=_mat(Color(0.1,0.16,0.18,0.3),0.9,0, true) if transparent else ShaderMaterial.new()
	if not transparent:rubber.shader=load("res://assets/shaders/rally_tyre.gdshader")
	var tyre := SurfaceTool.new();tyre.begin(Mesh.PRIMITIVE_TRIANGLES)
	var profile := [[-width*0.5,radius*0.61],[-width*0.55,radius*0.78],[-width*0.47,radius*0.94],[-width*0.33,radius],[width*0.33,radius],[width*0.47,radius*0.94],[width*0.55,radius*0.78],[width*0.5,radius*0.61]]
	for ring in profile.size()-1:
		for segment in 48:
			for coordinate in [[ring,segment],[ring+1,segment],[ring,segment+1],[ring,segment+1],[ring+1,segment],[ring+1,segment+1]]:
				var spec: Array=profile[coordinate[0]];var angle: float=coordinate[1]*TAU/48.0
				var normal := Vector3(0,cos(angle),sin(angle))
				if ring<2:normal=Vector3(-0.90,normal.y*0.42,normal.z*0.42).normalized()
				elif ring>4:normal=Vector3(0.90,normal.y*0.42,normal.z*0.42).normalized()
				tyre.set_normal(normal);tyre.set_uv(Vector2(coordinate[1]/48.0,coordinate[0]/7.0))
				tyre.add_vertex(Vector3(spec[0],cos(angle)*spec[1],sin(angle)*spec[1]))
	var tyre_node := MeshInstance3D.new();tyre_node.name="RoundedTyre";tyre_node.mesh=tyre.commit();tyre_node.material_override=rubber;spin.add_child(tyre_node)
	var rim := _mat(Color("d3d4c9"),0.30,0.68,transparent)
	var recess := _mat(Color("242a2b"),0.80,0.12,transparent)
	var metal := _mat(Color("737c7e"),0.42,0.78,transparent)
	# Barrel, brake disc and face detail use shared materials and are batched per wheel.
	for spec in [[radius*0.60,width*0.85,recess],[radius*0.49,width*0.82,metal]]:
		var disk := CylinderMesh.new();disk.top_radius=spec[0];disk.bottom_radius=spec[0];disk.height=spec[1];disk.radial_segments=32
		var node := MeshInstance3D.new();node.mesh=disk;node.rotation.z=PI/2;node.material_override=spec[2];spin.add_child(node)
	for side in [-1.0,1.0]:
		var face: float=side*width*0.51
		var lip := SurfaceTool.new();lip.begin(Mesh.PRIMITIVE_TRIANGLES)
		for segment in 48:
			var face_indices := [[0,segment],[1,segment],[0,segment+1],[0,segment+1],[1,segment],[1,segment+1]]
			if side>0:face_indices=[[1,segment],[0,segment],[0,segment+1],[1,segment],[0,segment+1],[1,segment+1]]
			for coordinate in face_indices:
				var radial := radius*(0.54 if coordinate[0]==0 else 0.62)
				var angle: float=coordinate[1]*TAU/48.0
				lip.set_normal(Vector3(side,0,0));lip.add_vertex(Vector3(face,cos(angle)*radial,sin(angle)*radial))
		var lip_node := MeshInstance3D.new();lip_node.mesh=lip.commit();lip_node.material_override=rim;spin.add_child(lip_node)
		for spoke in 8:
			var angle := spoke*TAU/8
			var center := Vector3(face-side*0.012,cos(angle)*radius*0.34,sin(angle)*radius*0.34)
			var bar := _box(spin,Vector3(0.025,radius*0.43,0.046),center,rim);bar.rotation.x=angle
		var hub := CylinderMesh.new();hub.top_radius=radius*0.16;hub.bottom_radius=radius*0.16;hub.height=0.04;hub.radial_segments=16
		var hub_node := MeshInstance3D.new();hub_node.mesh=hub;hub_node.rotation.z=PI/2;hub_node.position.x=face;hub_node.material_override=rim;spin.add_child(hub_node)
		for bolt in 5:
			var angle := bolt*TAU/5
			_box(spin,Vector3(0.013,0.014,0.014),Vector3(face+side*0.024,cos(angle)*radius*0.1,sin(angle)*radius*0.1),recess)
	_merge_meshes(spin)
