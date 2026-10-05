extends SceneTree
func _initialize() -> void:call_deferred("capture")
func capture() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	for i in 5:await process_frame
	var game := current_scene
	game.active_track=3;game.active_car=10
	game.start_race();game.countdown=0
	print("capture: started")
	for i in 60:await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("../outputs/GhostRally-0.15.0-start.png")
	print("capture: start saved")
	# A second view shows the mapped terminus and hotel rather than hiding them behind the car.
	game.set_physics_process(false)
	game.camera.position=game.world.geo_to_world(51.5739,14.0112)+Vector3(0,28,0)
	game.camera.look_at(game.world.geo_to_world(51.57515,14.0101)+Vector3.UP*2)
	for i in 5:await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("../outputs/GhostRally-0.15.0-area.png")
	print("capture: area saved")
	# Stationary in-game inspection view; no synthetic speed or frame overlay.
	game.car.position=game.world.center_at(1200)+Vector3(0,0.07,0)
	game.yaw=game.world.heading_at(1200);game.car.rotation.y=game.yaw
	game.velocity=Vector2.ZERO;game.speed=0;game.dynamics.reset()
	var back=Vector3(sin(game.yaw),0,cos(game.yaw))
	game.camera.position=game.car.position+back*9.5+Vector3(0,3.4,0)
	game.camera.look_at(game.car.position-back*12+Vector3(0,1,0))
	game.race_progress=1200
	game.minimap.progress=1200;game.minimap.player_position=game.car.position;game.minimap.queue_redraw()
	game.speed_label.text="1  000 KM/H"
	for i in 5:await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("../outputs/GhostRally-0.15.0-race.png")
	for wp in 3:
		game.active_wp=wp;game.show_pre_race()
		for i in 5:await process_frame
		await RenderingServer.frame_post_draw
		get_root().get_texture().get_image().save_png("../outputs/GhostRally-0.15.0-WP%d.png" % [wp+1])
	quit()
