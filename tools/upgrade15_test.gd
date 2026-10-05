extends SceneTree
var failed := false
func check(ok: bool, message: String) -> void:
	if not ok: failed=true;push_error(message)
func _initialize() -> void:call_deferred("run_test")
func run_test() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	for i in 4:await process_frame
	var game := current_scene
	game.set_physics_process(false)
	game.active_track=3;game.active_car=10;game.start_race();game.countdown=0
	check(game.Data.CARS[10].name=="Lovo 940 VOC","fictional vehicle name")
	game.touch={1:Vector2(1100,620)};game.touch_anchor=game.touch.duplicate()
	game.show_pause()
	check(game.touch.is_empty() and game.touch_anchor.is_empty(),"pause clears held inputs")
	game.state="race";game.build_race_ui()
	# Sparse timestamps after a collision penalty must interpolate by actual times.
	game.replay_frames=[[0.0,0.0,0.0,0.0,0,0,0,0,0.1],[0.1,1.0,0.0,0.0,0,0,0,0,0.2],[2.1,21.0,0.0,0.0,0,0,0,0,2.2],[2.2,22.0,0.0,0.0,0,0,0,0,2.3]]
	game.replay_index=0;game.race_time=1.1;game.update_replay()
	check(absf(game.ghost_car.position.x-11.0)<0.01,"ghost interpolates across penalty interval")
	check(absf(game.ghost_car.position.y-1.2)<0.01,"ghost preserves height")
	game.race_time=2.15;game.update_replay()
	check(absf(game.ghost_car.position.x-21.5)<0.01,"ghost cursor advances by timestamps")
	game.replay_frames.clear()
	game.checkpoint=2;game.race_time=60;game.previous_best=1
	game.car.position=game.world.center_at(game.world.track.length-4)
	var races_before: int=game.save.races
	game._physics_process(1.0/60)
	check(game.state=="result","finish safely exits race UI update")
	game.finish_race()
	check(int(game.save.races)==races_before+1,"finish reward cannot be duplicated")
	if not failed:print("PASS: Lovo naming, pause input reset, timestamp/height replay and finish transition")
	quit(1 if failed else 0)
