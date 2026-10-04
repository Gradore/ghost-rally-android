extends SceneTree
var failed := false
func check(ok: bool, message: String) -> void:
	if not ok:push_error(message);failed=true
func _initialize() -> void:call_deferred("run_test")
func run_test() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	for i in 4:await process_frame
	var game := current_scene
	game.active_track=3;game.active_car=10;game.start_race();game.set_physics_process(false)
	check(game.world.contact_height(game.world.center_at(100),100)==0,"sealed start stays flat")
	var p := 1200.0
	var mesh: MeshInstance3D=game.world.road.get_child(1)
	var vertices: PackedVector3Array=mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var road_height := float(vertices[int(p/5)*6].y)
	check(absf(road_height-0.025-game.world.contact_height(game.world.center_at(p),p))<0.02,"road mesh and sampled wheel ground agree")
	game.car.position=game.world.center_at(p)+Vector3(0,0.07,0)
	game.race_progress=p;game.yaw=game.world.heading_at(p);game.velocity=Vector2.ZERO
	game.throttle=0;game.brake=0;game.steer=0
	for i in 120:game.update_vehicle(1.0/60)
	check(game.dynamics.suspension.initialized,"world adapter initializes suspension")
	check(absf(game.car.position.y-0.07-game.dynamics.suspension.height+game.dynamics.suspension.ride_height)<0.001,"body heave reaches scene")
	check(absf(game.car.body.rotation.x-game.dynamics.suspension.pitch)<0.001,"render pitch comes from forces")
	var key720: String=game.record_key();game.dynamics.set_tick_hz(360)
	check(key720!=game.record_key(),"best-time keys separate integration presets")
	if not failed:print("PASS: sealed start, matching road/contact heights, physical body pose, preset-specific best times")
	quit(1 if failed else 0)
