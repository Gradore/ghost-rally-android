extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	for i in 20: await process_frame
	var game := current_scene
	game.active_track=0
	game.start_race()
	game.countdown=-1.0
	for i in 30: await process_frame
	get_root().get_texture().get_image().save_png("E:/GhostRallyBuild/tools/Preview-Rallyfahrt.png")
	quit()
