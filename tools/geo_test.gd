extends SceneTree

var failed := false

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	for i in 4: await process_frame
	var game := current_scene
	if game.Data.TRACKS.size()!=16: fail("expected 16 states")
	var routes: Array=JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/routes.json"))
	for i in routes.size():
		game.active_track=i
		game.build_world()
		await process_frame
		var length: float=game.world.track.length
		if length<3500 or length>18000: fail("bad length " + str(i))
		for fraction in [0.1,0.5,0.9]:
			var progress: float=length*fraction
			var p: Vector3=game.world.center_at(progress)
			if absf(game.world.progress_at(p,progress)-progress)>2.0: fail("progress projection " + str(i))
			if absf(game.world.lateral_offset(p))>1.0: fail("centerline offset " + str(i))
			var road_mesh := game.world.road.get_child(1) as MeshInstance3D
			var vertices: PackedVector3Array=road_mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			var segment: int=int(progress/5.0)
			var across: Vector3=vertices[segment*6+2]-vertices[segment*6]
			var along: Vector3=game.world.center_at(progress+2.0)-game.world.center_at(progress-2.0)
			if across.length()<5.5 or absf(across.normalized().dot(along.normalized()))>0.2: fail("road cross section " + str(i))
		for child in game.world.scenery.get_children():
			if child is StaticBody3D:
				var shape: Shape3D=child.get_child(0).shape
				var radius: float=shape.radius if shape is CylinderShape3D else maxf(shape.size.x,shape.size.z)*0.5
				var nearest: Vector2=game.world._nearest(child.position)
				var clearance: float=game.world.road_width_at(nearest.x)*0.5+radius+0.35
				if nearest.y<clearance*clearance: fail("obstacle on road " + str(i)+" at "+str(child.position)+" clearance "+str(sqrt(nearest.y))+" radius "+str(radius))
		if game.world.tree_centers.size()<25: fail("missing tree contacts " + str(i))
		for tree_index in mini(5,game.world.tree_centers.size()):
			var center: Vector2=game.world.tree_centers[tree_index]
			var contact: Dictionary=game.world.sweep_trees(Vector3(center.x,0,center.y+10.0),Vector3(center.x,0,center.y-10.0),1.25)
			if contact.is_empty(): fail("tree sweep misses mapped tree " + str(i))
	game.show_tracks()
	for i in 3: await process_frame
	if game.map_control.states.size()!=16: fail("map lacks state shapes")
	game.map_control.choose_code("09")
	await create_timer(1.5).timeout
	if game.active_track!=1 or game.map_control.stage!=2: fail("map zoom selection")
	if not failed:print("PASS: 16 routes, map zoom, route projection")
	quit(1 if failed else 0)

func fail(message: String) -> void:
	printerr("FAIL: "+message)
	failed=true
