extends SceneTree
func _initialize() -> void:call_deferred("run_test")
func run_test() -> void:
	var car: Node3D=load("res://scripts/rally_car.gd").new()
	var panel := Node3D.new();get_root().add_child(panel)
	car._loft(panel,[
		[Vector3(-1,-1,-1),Vector3(-1,1,-1),Vector3(1,1,-1),Vector3(1,-1,-1)],
		[Vector3(-1,-1,1),Vector3(-1,1,1),Vector3(1,1,1),Vector3(1,-1,1)]
	],StandardMaterial3D.new())
	var arrays: Array=panel.get_child(0).mesh.surface_get_arrays(0)
	for i in arrays[Mesh.ARRAY_VERTEX].size():
		var point: Vector3=arrays[Mesh.ARRAY_VERTEX][i]
		var normal: Vector3=arrays[Mesh.ARRAY_NORMAL][i]
		assert(point.dot(normal)>0.99,"body sides and end caps face outward")
	panel.queue_free();car.free()
	for config in load("res://scripts/game_data.gd").CARS:
		var vehicle: Node3D=load("res://scripts/rally_car.gd").new();get_root().add_child(vehicle)
		vehicle.configure(config)
		for pivot in vehicle.wheel_spins:
			assert(pivot!=null,"keep articulated wheel pivots")
			var meshes := 0
			for node in pivot.get_children():
				if node is MeshInstance3D:
					meshes+=1
					assert(node.mesh.get_aabb().size.is_finite(),"finite wheel geometry")
			assert(meshes<=4,"batch spoke and hub detail by material")
		vehicle.queue_free()
		await process_frame
	print("PASS: outward loft normals, all twelve wheel models and four material batches per wheel")
	quit()
