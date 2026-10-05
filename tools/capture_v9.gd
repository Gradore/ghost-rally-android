extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	for i in 24: await process_frame
	var game := current_scene
	game.active_track=4
	game.active_car=6
	game.show_pre_race()
	for i in 70: await process_frame
	get_root().get_texture().get_image().save_png("E:/GhostRallyBuild/outputs/Preview-Fahrzeugwahl-v9.png")
	game.start_race()
	game.countdown=-1.0
	game.car.position=game.world.center_at(game.world.track.length*0.53)+Vector3(0,0.07,0)
	game.yaw=game.world.heading_at(game.world.track.length*0.53)
	game.car.rotation.y=game.yaw
	for i in 55: await process_frame
	get_root().get_texture().get_image().save_png("E:/GhostRallyBuild/outputs/Preview-Rennen-v9.png")
	quit()
