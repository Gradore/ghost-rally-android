extends SceneTree
func _initialize() -> void:call_deferred("run_test")
func run_test() -> void:
	var world := TrackWorld.new();root.add_child(world);world.build(GameData.TRACKS[16])
	for i in 3:await process_frame
	assert(world.track.length>15000 and world.track.length<16000)
	assert(not world.gravel_at(10),"start is asphalt")
	var gravel := 0;var asphalt := 0
	for s in world.surface_segments:
		var p: float = (float(s.from)+float(s.to))*0.5*world.track.length/world.source_route_length
		assert(world.gravel_at(p)==bool(s.gravel),"physical contact follows mapped surface")
		assert(is_equal_approx(world.road_width_at(p),float(s.width)),"track width follows segment")
		if s.gravel:gravel+=1
		else:asphalt+=1
	assert(gravel>20 and asphalt>20,"both kinds exist")
	var mv: Node3D=world.scenery.get_child(1)
	for node in world.scenery.get_children():
		if node.get_script()!=null and node.get_script().resource_path.ends_with("mv_scenery.gd"):mv=node
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/mv_rostock.json"))
	assert(mv.footprint_reference.size()==data.buildings.size())
	for b in data.buildings:
		var p: PackedVector2Array=mv.footprint_reference[str(b.id)]
		var middle := Vector2.ZERO
		for point in p:middle+=point
		middle/=float(p.size())
		if b.tags.get("location","")!="underground" and int(b.tags.get("layer","0"))>=0 and Geometry2D.is_point_in_polygon(middle,p):assert(not world.scenery_clear(Vector3(middle.x,0,middle.y),0),"broad phase protects mapped house plots")
		for i in p.size():
			var expected := world.geo_to_world(float(b.p[i][0]),float(b.p[i][1]))
			assert(Vector3(p[i].x,0,p[i].y).distance_to(expected)<0.02,"no house repositioning")
	assert(world.tree_centers.size()>25,"mapped woodland/tree contacts")
	assert(GameData.TRACKS[7].name=="MÜRITZ TRAIL","original MV stage preserved")
	print("PASS: MV mixed surfaces and widths, ",data.buildings.size()," world footprints; original Müritz preserved")
	world.queue_free();await process_frame;quit()
