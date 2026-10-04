extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	for i in 2: await process_frame
	current_scene.show_garage()
	for i in 50: await process_frame
	root.get_viewport().get_texture().get_image().save_png("res://preview_garage.png")
	quit()
