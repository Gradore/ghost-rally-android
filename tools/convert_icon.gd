extends SceneTree

func _initialize() -> void:
	var source := FileAccess.get_file_as_string("res://assets/icon.svg")
	var image := Image.new()
	var err := image.load_svg_from_string(source,1.0)
	if err == OK:
		image.save_png("res://assets/icon.png")
	quit(err)
