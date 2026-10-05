extends SceneTree

var failed := false

func _initialize() -> void:
	call_deferred("run_test")

func check(condition: bool, message: String) -> void:
	if not condition:
		printerr("FAIL: "+message)
		failed=true

func run_test() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	for i in 4: await process_frame
	var game := current_scene
	game.active_track=0
	game.active_car=0
	game.show_pre_race()
	check(game.state=="prerace","car selection screen missing")
	game.select_pre_race_car(1)
	check(game.active_car==1,"pre-race car selection failed")
	game.select_pre_race_car(-1)
	game.start_race()
	game.countdown=-1.0
	check(is_instance_valid(game.minimap) and game.minimap.track_world==game.world,"race minimap missing")
	var screen_size: Vector2=game.get_viewport().get_visible_rect().size
	game.touch[0]=Vector2(screen_size.x*0.93,screen_size.y*0.88)
	game.get_controls()
	check(game.throttle>0.9 and game.brake==0.0,"gas button should accelerate")
	game.touch[0]=Vector2(screen_size.x*0.79,screen_size.y*0.88)
	game.get_controls()
	check(game.brake>0.9 and game.throttle==0.0,"brake button should brake")
	game.touch.clear()
	var original_mode: int=game.camera_mode
	game.toggle_camera()
	check(game.camera_mode!=original_mode,"camera toggle")
	var start: Vector3=game.car.position
	var forward := Vector3(-sin(game.yaw),0,-cos(game.yaw))
	game.world.add_obstacle(start+forward*18.0+Vector3.UP,Vector3(3.0,2.0,3.0))
	for i in 3: await physics_frame
	game.throttle=1.0
	for i in 240: game.update_vehicle(1.0/60.0)
	check(game.collision_count>0,"no obstacle collision")
	check(game.car.position.distance_to(start)<20.0,"car passed through obstacle")
	check(game.crash_energy>0.0,"no crash feedback")
	# Isolate manual collision probes from the live input/vehicle tick.
	game.set_physics_process(false)
	game.velocity=Vector2.ZERO
	var first_tree: StaticBody3D=null
	var tree_count := 0
	for child in game.world.scenery.get_children():
		if child is StaticBody3D and child.is_in_group("rally_tree"):
			tree_count+=1
			if first_tree==null: first_tree=child
	check(tree_count>100,"too few tree colliders")
	check(is_instance_valid(first_tree),"tree collider missing")
	if is_instance_valid(first_tree):
		game.car.position=Vector3(first_tree.position.x,0.07,first_tree.position.z+8.0)
		for i in 2: await physics_frame
		var tree_hit: KinematicCollision3D=game.car.move_and_collide(Vector3(0,0,-12.0))
		check(tree_hit!=null and tree_hit.get_collider()==first_tree,"car passes through tree")
		game.car.position=Vector3(first_tree.position.x,0.07,first_tree.position.z+12.0)
		game.yaw=0.0
		game.steer=0.0
		game.throttle=0.0
		game.brake=0.0
		game.velocity=Vector2(0,-35.0)
		for i in 36: game.update_vehicle(1.0/60.0)
		check(game.car.position.z>first_tree.position.z+1.5,"high-speed car passed through tree")
	var sampled := 0
	var stopped := 0
	for child in game.world.scenery.get_children():
		if child is StaticBody3D and child.is_in_group("rally_tree") and sampled<12:
			if tree_count%17==0 or sampled==0:
				# Dense forests can overlap the old teleport position. Start clear of all trunks.
				var approach := Vector3.ZERO
				for direction in [Vector3.BACK,Vector3.RIGHT,Vector3.FORWARD,Vector3.LEFT]:
					var candidate: Vector3=Vector3(child.position.x,0.07,child.position.z)+direction*8.0
					var clear := true
					for tree_i in game.world.tree_centers.size():
						if Vector2(candidate.x,candidate.z).distance_to(game.world.tree_centers[tree_i])<game.world.tree_radii[tree_i]+2.0:
							clear=false;break
					if clear: approach=direction;break
				check(approach!=Vector3.ZERO,"no unobstructed tree probe start")
				game.car.position=Vector3(child.position.x,0.07,child.position.z)+approach*8.0
				for i in 2: await physics_frame
				var hit: KinematicCollision3D=game.car.move_and_collide(-approach*12.0)
				if hit!=null: stopped+=1
				sampled+=1
			tree_count-=1
	print("tree samples:",sampled," stopped:",stopped)
	check(sampled>=10 and stopped==sampled,"tree collision sample failed")
	game.show_home()
	check(game.state=="home","cannot return to main menu")
	if not failed: print("PASS: tree collision, buttons, minimap, crash response, onboard toggle, main-menu exit")
	quit(1 if failed else 0)
