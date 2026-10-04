extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	for i in 3: await process_frame
	var game := current_scene
	game.active_track=4
	game.build_world()
	var p: float=game.world.track.length*0.53
	print("ROAD",game.world.road_width,game.world.road_width_at(p),p," center ",game.world.center_at(p))
	var idx: int=int(p/5.0)
	for i in range(2):
		var mesh := game.world.road.get_child(i) as MeshInstance3D
		var vertices: PackedVector3Array=mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		print("MESH ",i," segment width ",vertices[idx*6].distance_to(vertices[idx*6+1])," vertices ",vertices[idx*6],vertices[idx*6+1])
	quit()
