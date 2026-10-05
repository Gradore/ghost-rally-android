extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func _shot(name: String) -> void:
	get_root().get_texture().get_image().save_png("E:/GhostRallyBuild/outputs/"+name)

func capture() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	for i in 20: await process_frame
	var game := current_scene
	game.show_garage()
	for i in 25: await process_frame
	_shot("Preview-Garage-v3.png")
	game.show_tracks()
	for i in 20: await process_frame
	_shot("Preview-Deutschlandkarte-v3.png")
	game.map_control.choose_code("12")
	await create_timer(1.8).timeout
	for i in 12: await process_frame
	_shot("Preview-Grossraeschen-Karte.png")
	game.show_tracks()
	game.map_control.choose_code("11")
	await create_timer(1.8).timeout
	for i in 12: await process_frame
	_shot("Preview-Berlin-Karte.png")
	game.active_track=2
	game.start_race()
	game.countdown=-1.0
	game.car.position=game.world.center_at(game.world.track.length*0.43)+Vector3(0,0.07,0)
	game.yaw=game.world.heading_at(game.world.track.length*0.43)
	game.car.rotation.y=game.yaw
	for i in 40: await process_frame
	_shot("Preview-Berlin-Rennen.png")
	game.active_track=5
	game.start_race()
	game.countdown=-1.0
	game.car.position=game.world.center_at(game.world.track.length*0.38)+Vector3(0,0.07,0)
	game.yaw=game.world.heading_at(game.world.track.length*0.38)
	game.car.rotation.y=game.yaw
	for i in 40: await process_frame
	_shot("Preview-Hamburg-Rennen.png")
	quit()
