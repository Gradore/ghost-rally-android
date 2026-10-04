extends SceneTree
var failed := false
func check(ok: bool,msg: String) -> void:
	if not ok:failed=true;push_error(msg)
func _initialize() -> void:call_deferred("run_test")
func run_test() -> void:
	var filter=preload("res://scripts/input/mobile_steering.gd").new()
	var old := 0.0
	for i in 60:
		var value: float=filter.step(1,20,1.0/60)
		check(value>=old-0.001 and value-old<0.15,"smooth monotonic steering without snap");old=value
	for i in 60:old=filter.step(0,20,1.0/60)
	check(absf(old)<0.001,"steering self-centers after release")
	change_scene_to_file("res://scenes/main.tscn")
	for i in 4:await process_frame
	var game := current_scene;game.active_track=3
	var endpoints: Array[Vector3]=[];var lengths := 0.0
	for wp in 3:
		game.active_wp=wp;game.build_world();await process_frame
		lengths+=float(game.world.track.length)
		if wp>0:check(endpoints[-1].distance_to(game.world.center_at(0))<0.01,"WP boundaries connect exactly")
		endpoints.append(game.world.center_at(game.world.track.length))
		check(game.world.track.length>4500 and game.world.track.length<6000,"WP is about one third of the loop")
		check(game.record_key().ends_with("wp%d" % wp),"independent WP best-time key")
	check(absf(lengths-float(game.world.track.full_length))<0.1,"three WPs cover the full route without shortcuts")
	game.active_wp=0;game.build_world();await process_frame
	check(endpoints[-1].distance_to(game.world.center_at(0))<0.01,"WP3 finishes at original start pin")
	check(not game.world.gravel_at(100),"original sealed start retained")
	check(game.engine_layers.size()==1 and game.engine_layers[0].stream is AudioStreamWAV,"recorded motor sound loaded")
	check(game.engine_layers[0].stream.loop_mode==AudioStreamWAV.LOOP_FORWARD,"recording loops")
	var screen: Vector2=game.get_viewport().get_visible_rect().size
	game.touch={2:screen*Vector2(0.19,0.85)};game.touch_anchor={2:screen*Vector2(0.142,0.847)};game.save.control_mode="wheel";game.get_controls()
	check(game.steer>0 and game.steer<1,"touch drag produces analog steering")
	game.touch.clear();game.get_controls();check(game.steer==0,"release clears target")
	var pines := 0
	for node in game.world.scenery.get_children():
		if node.is_in_group("spatial_pines"):
			pines+=node.multimesh.instance_count
			check(node.multimesh.mesh.get_surface_count()==2,"spatial trunk and needle geometry")
			for tree_i in range(0,node.multimesh.instance_count,maxi(1,node.multimesh.instance_count/5)):
				# Dummy rendering does not retain MultiMesh transforms. Validate submitted roots there.
				var base: Vector3=node.get_meta("ground_roots")[tree_i] if DisplayServer.get_name()=="headless" else node.position+node.multimesh.get_instance_transform(tree_i).origin
				check(absf(base.y-(game.world.ground_height(base)-0.08))<0.01,"tree root follows actual terrain height")
	check(pines>100,"3D near forest present")
	for i in range(0,game.world.tree_centers.size(),maxi(1,game.world.tree_centers.size()/20)):
		var at=game.world.tree_centers[i];var y: float=game.world.ground_height(Vector3(at.x,0,at.y))
		check(is_finite(y),"tree support has finite terrain height")
	if not failed:print("PASS: three connected WPs, isolated times, recorded loop, smooth analog touch and spatial forest")
	quit(1 if failed else 0)
