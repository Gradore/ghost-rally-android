extends Node3D
# Original small showroom: no track geometry or race colliders are loaded here.
var preview: RallyCar
var selected_id := ""
var selected_livery := -1
func material(color: Color, metal: float=0.0, rough: float=0.7) -> StandardMaterial3D:
	var m := StandardMaterial3D.new();m.albedo_color=color;m.metallic=metal;m.roughness=rough
	return m
func box(size: Vector3, at: Vector3, m: Material) -> void:
	var n := MeshInstance3D.new();var mesh := BoxMesh.new();mesh.size=size
	n.mesh=mesh;n.material_override=m;n.position=at;add_child(n)
func _ready() -> void:
	var floor_mat := material(Color("454a4d"),0.2,0.36)
	var wall := material(Color("3c4953"));var dark := material(Color("19232b"));var steel := material(Color("8d969a"),0.65)
	box(Vector3(24,0.2,20),Vector3(0,-0.18,0),floor_mat)
	box(Vector3(24,0.1,20),Vector3(0,5.4,0),dark)
	box(Vector3(24,6,0.2),Vector3(0,2.8,-7),wall)
	box(Vector3(0.2,6,20),Vector3(-10,2.8,0),wall)
	box(Vector3(6,4.3,0.13),Vector3(-1,2.1,-6.85),dark)
	for j in 12: box(Vector3(5.8,0.035,0.09),Vector3(-1,0.2+j*0.34,-6.73),steel)
	box(Vector3(4,0.15,1.4),Vector3(5,1.0,-5.5),steel)
	for x in [3.4,6.6]:box(Vector3(0.14,1,1.1),Vector3(x,0.45,-5.5),dark)
	box(Vector3(2,0.9,0.9),Vector3(-6,0.45,-5.5),material(Color("a23e28"),0.3))
	for j in 4: box(Vector3(1.9,0.028,0.02),Vector3(-6,0.2+j*0.2,-5.04),steel)
	var rubber := material(Color("131719"))
	for j in 3:
		var tyre := MeshInstance3D.new();var mesh := TorusMesh.new();mesh.inner_radius=0.21;mesh.outer_radius=0.37;mesh.rings=16;mesh.ring_segments=8
		tyre.mesh=mesh;tyre.material_override=rubber;tyre.position=Vector3(-4.2,0.22+j*0.28,-5.3);add_child(tyre)
	var strip := material(Color("faf6e6"));strip.emission_enabled=true;strip.emission=Color("fff2d6");strip.emission_energy_multiplier=2
	for x in [-5,0,5]:
		box(Vector3(0.1,0.04,6),Vector3(x,5.0,-1),strip)
		var light := OmniLight3D.new();light.position=Vector3(x,4.0,-0.5);light.light_energy=1.1;light.omni_range=12;light.shadow_enabled=false;add_child(light)
	# Wall band and tool storage use original simple geometry.
	box(Vector3(24,0.25,0.05),Vector3(0,1.1,-6.86),material(Color("c0a452")))
	# Painted service-bay markings.
	var yellow := material(Color("c0a452"))
	for x in [-2.1,2.1]:box(Vector3(0.05,0.012,6.2),Vector3(x,-0.066,0),yellow)
	box(Vector3(4.2,0.012,0.05),Vector3(0,-0.066,3.1),yellow)
func select_car(config: Dictionary, livery: int) -> void:
	if selected_id==config.id and selected_livery==livery and is_instance_valid(preview):return
	if is_instance_valid(preview):preview.hide();preview.queue_free()
	selected_id=config.id;selected_livery=livery
	preview=preload("res://scripts/rally_car.gd").new();add_child(preview)
	preview.configure(config,false,livery);preview.collision_layer=0;preview.collision_mask=0
	for node in preview.body.get_children():
		if node is MeshInstance3D and node.material_override is ShaderMaterial and node.material_override.shader.resource_path.ends_with("rally_paint.gdshader"):
			node.material_override.set_shader_parameter("dirt_amount",0.0)
	preview.position=Vector3.ZERO;preview.rotation.y=-0.45
