extends SceneTree
func _initialize() -> void:call_deferred("run_test")
func run_test() -> void:
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/mv_rostock.json"))
	var reference: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/streetview_reference.json"))
	assert(reference.views.size()==5)
	var found := false
	for road in data.roads:
		if str(road.id)=="687183780":assert(road.highway=="footway");found=true
	assert(found,"Mönchhagen footway classified from original OSM")
	var scenery := preload("res://scripts/mv_scenery.gd").new()
	var points := PackedVector2Array([Vector2(0,0),Vector2(5,0),Vector2(10,0),Vector2(10,8),Vector2(0,8)])
	var roof: PackedVector2Array=scenery.roof_outline(points)
	assert(roof.size()==4 and points.size()==5,"roof simplification never mutates source polygon")
	scenery.free()
	var world := TrackWorld.new();root.add_child(world);world.build(GameData.TRACKS[16])
	for i in 3:await process_frame
	assert(world.scenery.find_children("StreetReferenceDetails*","MultiMeshInstance3D",true,false).size()>=3,"batched reference details present")
	world.queue_free();await process_frame
	print("PASS: source highway classification, preserved roof outline, batched Street View reference details");quit()
