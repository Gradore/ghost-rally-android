extends SceneTree

var failed := false

func _initialize() -> void:
	call_deferred("run_test")

func check(ok: bool, message: String) -> void:
	if not ok:
		printerr("FAIL: "+message)
		failed=true

func run_test() -> void:
	var save_path := ProjectSettings.globalize_path("user://save.json")
	var existed := FileAccess.file_exists(save_path)
	var backup := FileAccess.get_file_as_string(save_path) if existed else ""
	change_scene_to_file("res://scenes/main.tscn")
	for i in 4: await process_frame
	var game := current_scene
	game.save=game.Data.default_save()
	game.active_car=0
	game.buy_upgrade("engine")
	check(int(game.save.rc)==200 and int(game.save.upgrades[0].engine)==1,"first RC upgrade")
	game.buy_upgrade("engine")
	check(int(game.save.rc)==0 and int(game.save.upgrades[0].engine)==2,"second RC upgrade")
	game.buy_upgrade("engine")
	check(int(game.save.rc)==0 and int(game.save.upgrades[0].engine)==2,"overspending allowed")
	if existed:
		var file := FileAccess.open(save_path,FileAccess.WRITE)
		file.store_string(backup)
	else:
		DirAccess.remove_absolute(save_path)
	if not failed: print("PASS: RC upgrades, prices, balance guard")
	quit(1 if failed else 0)
