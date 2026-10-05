extends SceneTree
func _initialize() -> void:call_deferred("capture")
func snap(name: String) -> void:
	for i in 10:await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../outputs/GhostRally-0.30.0-"+name+".png"))==OK)
func capture() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	for i in 5:await process_frame
	var game := current_scene
	game.settings_tab=4;game.show_settings();await snap("input-settings")
	game.active_car=10;game.show_garage()
	game.showroom.turntable=false;game.showroom.view_angle=PI-.45;game.showroom.preview.rotation.y=PI-.45
	await snap("lovo-garage")
	print("PASS: actual Mobile renderer captures saved")
	quit()
