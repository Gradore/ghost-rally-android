extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	for i in 24: await process_frame
	var game := current_scene
	game.active_track=3
	game.start_race()
	game.countdown=-1.0
	game.car.position=game.world.center_at(650.0)+Vector3(0,0.07,0)
	game.yaw=game.world.heading_at(650.0)
	game.car.rotation.y=game.yaw
	game.speed=38.0
	game.velocity=Vector2(-sin(game.yaw),-cos(game.yaw))*38.0
	for i in 60: await process_frame
	get_root().get_texture().get_image().save_png("E:/GhostRallyBuild/outputs/Preview-Grossraeschen-v4.png")
	game.toggle_camera()
	for i in 50: await process_frame
	get_root().get_texture().get_image().save_png("E:/GhostRallyBuild/outputs/Preview-Cockpit-v4.png")
	game.toggle_camera()
	var peak := 0.0
	var bend := 500.0
	for p in range(150,int(game.world.track.length)-150,10):
		var angle := absf(wrapf(game.world.heading_at(float(p)+18.0)-game.world.heading_at(float(p)-18.0),-PI,PI))
		if angle>peak:
			peak=angle
			bend=float(p)
	game.car.position=game.world.center_at(bend-45.0)+Vector3(0,0.07,0)
	game.yaw=game.world.heading_at(bend-45.0)
	game.car.rotation.y=game.yaw
	game.velocity=Vector2.ZERO
	game.speed=0.0
	for i in 55: await process_frame
	get_root().get_texture().get_image().save_png("E:/GhostRallyBuild/outputs/Preview-Engstelle-v5.png")
	print("Worst bend",bend,peak)
	quit()
