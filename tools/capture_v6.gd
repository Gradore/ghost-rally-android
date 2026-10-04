extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	for i in 25: await process_frame
	var game := current_scene
	game.show_garage()
	for i in 30: await process_frame
	get_root().get_texture().get_image().save_png("E:/GhostRallyBuild/outputs/Preview-Garage-v7.png")
	game.active_track=4
	game.start_race()
	game.countdown=-1.0
	var point: float=game.world.track.length*0.53
	game.car.position=game.world.center_at(point)+Vector3(0,0.07,0)
	game.yaw=game.world.heading_at(point)
	game.car.rotation.y=game.yaw
	game.race_progress=point
	for i in 55: await process_frame
	get_root().get_texture().get_image().save_png("E:/GhostRallyBuild/outputs/Preview-Bremen-v6.png")
	quit()
