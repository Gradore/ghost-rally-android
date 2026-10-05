extends SceneTree
func _initialize() -> void:call_deferred("capture")
func snap(name: String) -> void:
	for i in 8:await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("../game/outputs/GhostRally-0.22.0-"+name+".png")
func capture() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	for i in 4:await process_frame
	var game := current_scene
	game.active_car=10;game.show_garage()
	await snap("garage")
	game.show_home();await snap("home")
	game.show_settings();await snap("settings")
	game.active_track=16;game.start_race();game.set_physics_process(false);game.countdown=0;game.countdown_label.visible=false
	game.car.position=game.world.center_at(35)+Vector3.UP*0.07;game.yaw=game.world.heading_at(35);game.car.rotation.y=game.yaw
	var back := Vector3(sin(game.yaw),0,cos(game.yaw));game.camera.position=game.car.position+back*8+Vector3.UP*3;game.camera.look_at(game.car.position-back*14+Vector3.UP)
	await snap("race");print("CAPTURES SAVED");quit()
