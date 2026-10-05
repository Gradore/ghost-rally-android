extends SceneTree
const Data=preload("res://scripts/game_data.gd")
const World=preload("res://scripts/track_world.gd")
func _initialize() -> void:call_deferred("run")
func export_scene(node: Node, name: String) -> void:
	var doc := GLTFDocument.new();var state := GLTFState.new()
	assert(doc.append_from_scene(node,state)==OK)
	assert(doc.write_to_filesystem(state,"/tmp/ghost-unity-export/"+name+".glb")==OK)
func expand_instances(node: Node) -> void:
	for child in node.get_children():expand_instances(child)
	if node is MultiMeshInstance3D and node.multimesh!=null:
		var mm: MultiMesh=node.multimesh
		for i in mm.instance_count:
			var inst := MeshInstance3D.new();inst.mesh=mm.mesh;inst.transform=mm.get_instance_transform(i)
			inst.material_override=node.material_override;node.add_child(inst)
		node.multimesh=null
func run() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/ghost-unity-export")
	var catalog := {"cars":[],"tracks":[],"physicsVersion":"unity-wheel-1"}
	for data in Data.CARS:
		var car := RallyCar.new();root.add_child(car);car.configure(data)
		for i in 4:
			if car.wheel_spins[i]!=null:car.wheel_spins[i].get_parent().name=["wheel_fl","wheel_fr","wheel_rl","wheel_rr"][i]
		export_scene(car,data.id)
		var entry: Dictionary=data.duplicate();entry.color=data.color.to_html();catalog.cars.append(entry)
		car.queue_free();await process_frame
	for index in Data.TRACKS.size():
		var modes: Array=[-1,0,1,2] if index==3 else [-1]
		for wp in modes:
			var world := World.new();root.add_child(world)
			var track: Dictionary=Data.TRACKS[index].duplicate()
			if wp>=0:track.wp_index=wp
			# Same source-road loader and smoothing as the existing game, without scenery.
			world.track=track;world._load_route();world.road_width=6.4 if track.surface=="ASPHALT" else 5.6
			if index==16:
				world.official_height=preload("res://scripts/rostock_height27.gd").new()
				for i in range(int(ceil(float(world.track.length)/5))+2):world.official_road.append(world.official_height.sample(world.center_at(i*5)))
			var samples := [];var length: float=world.track.length
			for i in range(int(ceil(length/5))+1):
				var d := minf(i*5,length);var p: Vector3=world.center_at(d);p.y=world.road_relief(d)
				samples.append({"x":p.x,"y":p.y,"z":-p.z,"distance":d,"width":world.road_width_at(d),"gravel":world.gravel_at(d)})
			var id := "stage_%d_wp%d" % [index,wp]
			var item := {"id":id,"routeIndex":index,"wp":wp,"name":world.track.name,"length":length,"surface":track.surface,"originLat":world.origin_lat,"originLon":world.origin_lon,"rotation":world.metric_rotation,"samples":samples}
			catalog.tracks.append(item)
			world.queue_free();await process_frame
	var f := FileAccess.open("res://unity/Assets/Resources/Migration/catalog.json",FileAccess.WRITE);f.store_string(JSON.stringify(catalog));f.close()
	print("PASS: 12 cars and 20 stage selections exported")
	quit()
