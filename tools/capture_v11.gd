extends SceneTree
func _initialize() -> void:call_deferred("capture")
func capture() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	for i in 5:await process_frame
	var game := current_scene
	game.active_track=3;game.active_car=10
	game.show_pre_race()
	for i in 90:await process_frame
	get_root().get_texture().get_image().save_png("../outputs/GhostRally-0.11.0-stage.png")
	game.start_race();game.countdown=10
	game.car.position=game.world.center_at(game.world.track.length*0.42)+Vector3(0,0.07,0)
	game.yaw=game.world.heading_at(game.world.track.length*0.42)
	game.car.rotation.y=game.yaw
	for i in 90:await process_frame
	get_root().get_texture().get_image().save_png("../outputs/GhostRally-0.11.0-race.png")
	quit()
