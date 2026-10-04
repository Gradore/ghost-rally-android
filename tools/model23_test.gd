extends SceneTree
const Visual=preload("res://scripts/external_vehicle.gd")
func _initialize() -> void:call_deferred("run_test")
func run_test() -> void:
	var source := Node3D.new();root.add_child(source)
	var shell := MeshInstance3D.new();shell.name="Body";var mesh := BoxMesh.new();mesh.size=Vector3(1.75,1.2,4.87);shell.mesh=mesh;shell.position.y=0.9;source.add_child(shell)
	for i in 4:
		var wheel := MeshInstance3D.new();wheel.name=["wheel_fl","wheel_fr","wheel_rl","wheel_rr"][i]
		var cylinder := CylinderMesh.new();cylinder.height=0.195;cylinder.top_radius=0.317;cylinder.bottom_radius=0.317;cylinder.radial_segments=16
		wheel.mesh=cylinder;wheel.rotation.z=PI/2;wheel.position=Vector3(-0.82 if i%2==0 else 0.82,0.317,-1.385 if i<2 else 1.385);source.add_child(wheel)
	var document := GLTFDocument.new();var state := GLTFState.new()
	assert(document.append_from_scene(source,state)==OK)
	assert(document.write_to_filesystem(state,"user://model23-fixture.glb")==OK)
	source.queue_free();await process_frame
	var vehicle := RallyCar.new();root.add_child(vehicle);vehicle.configure(GameData.CARS[10])
	var collision_size := Vector3.ZERO
	for child in vehicle.get_children():
		if child is CollisionShape3D:collision_size=child.shape.size
	var profile := {"scene_path":"user://model23-fixture.glb","target_length_m":4.87,"wheel_nodes":{"front_left":"wheel_fl","front_right":"wheel_fr","rear_left":"wheel_rl","rear_right":"wheel_rr"},"max_triangles":100000}
	var result := Visual.attach(vehicle,GameData.CARS[10],profile)
	assert(not result.has("error") and result.articulated_wheels,"actual GLB loads with four wheel nodes")
	assert(absf(result.length_m-4.87)<0.001,"model normalized to metres")
	for child in vehicle.get_children():
		if child is CollisionShape3D:assert(child.shape.size==collision_size,"appearance import preserves native car collision")
	vehicle.update_wheel_visuals([{"spin":0.4},{"spin":0.4},{"spin":0.4},{"spin":0.4}])
	for spin in vehicle.wheel_spins:
		assert(is_equal_approx(spin.rotation.x,-0.4),"imported wheel follows simulation")
	vehicle.queue_free();await process_frame
	var fallback := RallyCar.new();root.add_child(fallback);fallback.configure(GameData.CARS[10])
	profile.max_triangles=1
	var refused := Visual.attach(fallback,GameData.CARS[10],profile)
	assert(refused.has("error") and fallback.body.visible,"over-budget GLB retains procedural fallback")
	print("PASS: actual GLB read, metre fit, four animated wheel nodes, native collider retained, over-budget fallback")
	fallback.queue_free();await process_frame;quit()
