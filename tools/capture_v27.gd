extends SceneTree
func _initialize() -> void:call_deferred("capture")
func snap(name: String) -> void:
 for i in 16:await process_frame
 await RenderingServer.frame_post_draw
 var target := ProjectSettings.globalize_path("res://").path_join("../outputs/GhostRally-0.27.0-"+name+".png")
 assert(get_root().get_texture().get_image().save_png(target)==OK)
func capture() -> void:
 change_scene_to_file("res://scenes/main.tscn")
 for i in 4:await process_frame
 var game := current_scene
 game.active_car=10;game.active_track=16;game.start_race();game.set_physics_process(false);game.countdown=0;game.countdown_label.visible=false
 var at: Vector3=game.world.geo_to_world(54.085938,12.18863)
 var progress: float=game.world.progress_at(at)
 game.car.position=game.world.center_at(progress)+Vector3.UP*(0.07+game.world.road_relief(progress));game.yaw=game.world.heading_at(progress);game.car.rotation.y=game.yaw
 game.camera.position=game.world.geo_to_world(54.085817,12.18867)+Vector3.UP*(4.8+game.world.ground_height(game.world.geo_to_world(54.085817,12.18867)))
 game.camera.look_at(game.world.geo_to_world(54.08624,12.18872)+Vector3.UP*(5+game.world.ground_height(game.world.geo_to_world(54.08624,12.18872))))
 await snap("rostock-haeuser")
 game.camera.position=game.world.geo_to_world(54.085865,12.18908)+Vector3.UP*(2+game.world.ground_height(game.world.geo_to_world(54.085865,12.18908)))
 game.camera.look_at(game.world.geo_to_world(54.08624,12.18863)+Vector3.UP*(4.5+game.world.ground_height(game.world.geo_to_world(54.08624,12.18863))))
 await snap("rostock-haltestelle")
 game.car.position=game.world.center_at(35)+Vector3.UP*(0.07+game.world.road_relief(35));game.yaw=game.world.heading_at(35);game.car.rotation.y=game.yaw
 var back := Vector3(sin(game.yaw),0,cos(game.yaw));game.camera.position=game.car.position+back*8+Vector3.UP*2.5;game.camera.look_at(game.world.center_at(100)+Vector3.UP*(game.world.road_relief(100)+1.2))
 await snap("rostock-anstieg")
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
