extends SceneTree
func _initialize() -> void:call_deferred("capture")
func capture() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	for i in 4:await process_frame
	var game := current_scene
	game.active_track=16;game.active_car=10;game.start_race();game.set_physics_process(false);game.countdown=0;game.countdown_label.visible=false
	game.car.position=game.world.center_at(35)+Vector3.UP*0.07;game.yaw=game.world.heading_at(35);game.car.rotation.y=game.yaw
	var back_start := Vector3(sin(game.yaw),0,cos(game.yaw));game.camera.position=game.car.position+back_start*8+Vector3.UP*3;game.camera.look_at(game.car.position-back_start*14+Vector3.UP)
	print("MV scene built")
	for i in 5:await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("../game/outputs/GhostRally-0.21.0-start.png")
	var anchors := [[54.08594,12.18860],[54.08999,12.21055],[54.15021,12.22242]]
	for i in anchors.size():
		var ll: Array=anchors[i];var at: Vector3=game.world.geo_to_world(float(ll[0]),float(ll[1]));var progress: float=game.world.progress_at(at)
		game.car.position=game.world.center_at(progress)+Vector3.UP*0.07;game.yaw=game.world.heading_at(progress);game.car.rotation.y=game.yaw
		var back := Vector3(sin(game.yaw),0,cos(game.yaw));game.camera.position=game.car.position+back*8+Vector3.UP*3;game.camera.look_at(game.car.position-back*14+Vector3.UP)
		game.minimap.progress=progress;game.minimap.player_position=game.car.position;game.minimap.queue_redraw()
		for f in 5:await process_frame
		await RenderingServer.frame_post_draw
		get_root().get_texture().get_image().save_png("../game/outputs/GhostRally-0.21.0-point%d.png" % [i+1])
	game.ui.visible=false;game.sky.environment.fog_enabled=false
	var center: Vector3=game.world.geo_to_world(54.08594,12.18860)
	var north: Vector3=(game.world.geo_to_world(54.08694,12.18860)-center).normalized()
	game.camera.projection=Camera3D.PROJECTION_ORTHOGONAL;game.camera.size=290;game.camera.position=center+Vector3.UP*250;game.camera.look_at(center,north)
	for i in 5:await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("../game/outputs/GhostRally-0.21.0-Rostock.png")
	print("MV captures saved");quit()
