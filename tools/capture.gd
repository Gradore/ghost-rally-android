extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	for i in 30: await process_frame
	var img := root.get_viewport().get_texture().get_image()
	img.save_png("res://preview.png")
	quit()
