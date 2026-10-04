extends SceneTree
func _initialize() -> void:call_deferred("run_test")
func run_test() -> void:
	await _batch_transform_test()
	var reference: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/grossraeschen_footprint_reference.json"))
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/start_area.json"))
	var camera := Camera3D.new();root.add_child(camera);camera.current=true
	var world := TrackWorld.new();root.add_child(world);world.build(GameData.TRACKS[3])
	for i in 3:await process_frame
	var area: Node3D=null
	for node in world.scenery.get_children():
		if node.get_script()!=null and node.get_script().resource_path.ends_with("start_area.gd"):area=node
	assert(area!=null,"mapped area exists")
	var count := 0
	for building in data.buildings:
		assert(reference.buildings.has(building.id),"independent source way exists")
		assert(building.p==reference.buildings[building.id].p,"stored footprint matches fetched OSM way")
		var node: Node3D=area.get_node("Building_"+str(building.id))
		var points: PackedVector2Array=node.get_meta("footprint")
		for i in points.size():
			var source: Array=reference.buildings[building.id].p[i]
			var expected := world.geo_to_world(float(source[0]),float(source[1]))
			var actual := node.to_global(Vector3(points[i].x,0,points[i].y))
			assert(actual.distance_to(expected)<0.02,"rendered footprint alignment in metres")
		if building.kind=="hotel":
			for child in node.get_children():
				if not child is MeshInstance3D:continue
				var vertices: PackedVector3Array=child.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
				for v in vertices:
					if v.y<=float(building.h)+0.2:continue
					var p := Vector2(v.x,v.z);var nearest := INF
					for edge in points.size():nearest=minf(nearest,p.distance_to(Geometry2D.get_closest_point_to_segment(p,points[edge],points[(edge+1)%points.size()])))
					assert(Geometry2D.is_point_in_polygon(p,points) or nearest<0.20,"hotel roof stays within T-shaped wings")
		if building.kind=="terraces":assert(node.get_meta("terrace_cubes")==3,"three terrace cubes")
		count+=1
	assert(count==81,"complete mapped start-area footprint set")
	var landmark_trees := area.find_children("landmark_oaks*","MultiMeshInstance3D",true,false)
	assert(not landmark_trees.is_empty(),"replace start-area tree cards with spatial crowns")
	print("PASS: 81 OSM footprints, world alignment, T-shaped hotel roofs and three IBA terrace cubes")
	world.queue_free();await process_frame;quit()

func _batch_transform_test() -> void:
	var fixture: Node3D=load("res://scripts/start_area.gd").new()
	root.add_child(fixture);fixture.rotation.y=0.31
	var detail: MeshInstance3D=fixture.box(fixture,Vector3(8,2,-5),Vector3(2,3,9),StandardMaterial3D.new())
	detail.rotation.y=0.74
	var actual: Transform3D=fixture.global_transform*fixture._detail_transform(detail)
	for corner in [Vector3(-0.5,-0.5,-0.5),Vector3(0.5,0.5,0.5),Vector3(0.5,-0.5,-0.5)]:
		var expected: Vector3=detail.global_transform*(corner*detail.mesh.size)
		assert((actual*corner).distance_to(expected)<0.0001,"batch preserves rotated detail scale in local axes")
	fixture._batch_details()
	fixture.queue_free();await process_frame
