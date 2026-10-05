extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	for i in 12: await process_frame
	var game := current_scene
	get_root().get_texture().get_image().save_png("E:/GhostRallyBuild/tools/Preview-Home-neu.png")
	game.show_tracks()
	for i in 20: await process_frame
	get_root().get_texture().get_image().save_png("E:/GhostRallyBuild/tools/Preview-Deutschlandkarte.png")
	game.map_control.choose_code("09")
	await create_timer(1.5).timeout
	for i in 6: await process_frame
	get_root().get_texture().get_image().save_png("E:/GhostRallyBuild/tools/Preview-Strecke-Bayern.png")
	quit()
