extends SceneTree
func _initialize() -> void:call_deferred("run_test")
func run_test() -> void:
	var camera := Camera3D.new();root.add_child(camera);camera.current=true
	var world := TrackWorld.new();root.add_child(world)
	world.build(GameData.TRACKS[3])
	for i in 3:await process_frame
	assert(world.terrain3d!=null,"Terrain3D adapter missing")
	assert(world.terrain3d.get("data").call("get_region_count")==4,"terrain region import incomplete")
	assert(world.relief!=null,"shore relief missing")
	assert(not world.gravel_at(100.0) and world.gravel_at(500.0),"start material/physics disagree")
	assert(absf(world.ground_height(world.center_at(100)))<1.0,"sealed start has unsupported road")
	var start_area: Node3D=null
	for node in world.scenery.get_children():
		if node.get_script()!=null and node.get_script().resource_path.ends_with("start_area.gd"):start_area=node
	assert(start_area!=null,"mapped landmarks missing")
	var batches := start_area.find_children("*","MultiMeshInstance3D",true,false)
	assert(batches.size()>5 and batches.size()<35,"landmark details must be batched for Android")
	var hotel_point := world.geo_to_world(51.5760,14.00927)
	assert(start_area.find_children("*","CollisionShape3D",true,false).size()>50,"building walls need collision")
	print("PASS: shore relief, sealed-start grip, mapped buildings, colliders, batched details ",batches.size())
	world.queue_free();await process_frame;quit()
