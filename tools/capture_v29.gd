extends SceneTree
func _initialize() -> void:call_deferred("capture")
func snap(name: String) -> void:
	for i in 20:await process_frame
	await RenderingServer.frame_post_draw
	var target := ProjectSettings.globalize_path("res://").path_join("../outputs/GhostRally-0.29.0-"+name+".png")
	assert(get_root().get_texture().get_image().save_png(target)==OK)
func capture() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	for i in 5:await process_frame
	var game := current_scene
	game.active_car=10;game.show_garage()
	game.showroom.turntable=false;game.showroom.view_angle=PI-0.45;game.showroom.preview.rotation.y=PI-0.45
	await snap("lovo-garage-front")
	game.showroom.rotate_view(PI)
	await snap("lovo-garage-rear")
	game.ui.hide()
	game.camera.position=Vector3(3.0,0.9,2.5)
	game.camera.look_at(Vector3(0.70,0.38,1.15).rotated(Vector3.UP,game.showroom.view_angle))
	await snap("lovo-wheel-detail")
	game.ui.show()
	game.active_track=16;game.start_race();game.set_physics_process(false);game.countdown=0;game.countdown_label.visible=false
	game.car.position=game.world.center_at(35)+Vector3.UP*(0.07+game.world.road_relief(35));game.yaw=game.world.heading_at(35);game.car.rotation.y=game.yaw
	var back := Vector3(sin(game.yaw),0,cos(game.yaw))
	game.camera.position=game.car.position+back*6.2+Vector3.UP*2.1
	game.camera.look_at(game.car.position+Vector3.UP*0.85)
	game.car.set_braking(true)
	await snap("lovo-rostock")
	game.ui.hide()
	game.camera.position=game.car.position-back*5.8+Vector3.UP*2.05
	game.camera.look_at(game.car.position+Vector3.UP*0.8)
	await snap("lovo-front-inspection")
	game.active_track=3;game.start_race();game.set_physics_process(false);game.countdown_label.visible=false
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/start_area.json"))
	var center := Vector3.ZERO
	for i in data.roundabout.size()-1:center+=game.world.geo_to_world(data.roundabout[i][0],data.roundabout[i][1])
	center/=float(data.roundabout.size()-1)
	game.car.position=game.world.center_at(25)+Vector3.UP*0.07;game.yaw=game.world.heading_at(25);game.car.rotation.y=game.yaw
	game.camera.position=center+Vector3(0,10,-23).rotated(Vector3.UP,game.world.metric_rotation)
	game.camera.look_at(center+Vector3.UP*1.4)
	await snap("grossraeschen-kreisel")
	print("LOCAL CAPTURES SAVED");current_scene.queue_free();await process_frame;preload("res://scripts/render/materials25.gd").cache.clear();preload("res://scripts/render/forest.gd").geometry_cache.clear();await process_frame;quit()
