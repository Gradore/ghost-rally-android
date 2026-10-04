extends SceneTree
var failed := false
func check(ok: bool, msg: String) -> void:
	if not ok:failed=true;push_error(msg)
func _initialize() -> void:call_deferred("run_test")
func run_test() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	for i in 4:await process_frame
	var game := current_scene
	check(not is_instance_valid(game.world),"home must not load a complete stage")
	game.active_car=10;game.show_garage();await process_frame
	var first: int= game.showroom.get_instance_id()
	game.select_garage_car(1);await process_frame
	check(game.active_car==11 and game.showroom.selected_id=="kestrel_s1_evo","right garage arrow selects next car")
	game.select_garage_car(-1);await process_frame
	check(game.active_car==10 and game.showroom.get_instance_id()==first,"garage is reused")
	var screen: Vector2=game.get_viewport().get_visible_rect().size
	game.save.control_mode="wheel";game.save.sensitivity=1
	for y in [0.70,0.78,0.85,0.95]:
		for x in [0.06,0.14,0.23]:
			var anchor := screen*Vector2(x,y)
			game.touch_anchor={0:anchor};game.touch={0:anchor-Vector2(screen.x*0.03,0)};game.get_controls()
			check(game.steer<0,"left thumb movement always steers left")
			game.touch={0:anchor+Vector2(screen.x*0.03,0)};game.get_controls()
			check(game.steer>0,"right thumb movement always steers right")
	game.touch.clear();game.touch_anchor.clear();game.get_controls();check(game.steer==0,"released thumb centers")
	game.tilt_zero=0;game.save.tilt_invert=false
	check(game.tilt_steering(-2)<0 and game.tilt_steering(2)>0,"calibrated tilt signs")
	check(game.tilt_steering(0.1)==0,"sensor deadzone")
	game.tilt_zero=1.5;check(game.tilt_steering(1.5)==0,"tilt neutral calibration")
	game.save.tilt_invert=true;check(game.tilt_steering(2)<0,"tilt inversion")
	game.active_track=16;game.start_race();game.set_physics_process(false)
	for i in 3:await physics_frame
	var before: int= game.world.get_instance_id();game.show_pause();game.settings_return="pause";game.show_settings();game.close_settings()
	check(game.state=="pause" and game.world.get_instance_id()==before,"settings returns to paused race")
	game.race_progress=600;game.car.position=Vector3(10000,0,10000);game.velocity=Vector2(20,4);game.reset_to_road()
	check(game.car.position.distance_to(game.world.center_at(600))<0.2 and game.speed==0 and game.state=="race","recovery resets to current road")
	game.start_race();check(game.world.get_instance_id()==before,"restart reuses loaded world")
	var mv: Node3D
	for node in game.world.scenery.get_children():
		if node.get_script()!=null and node.get_script().resource_path.ends_with("mv_scenery.gd"):mv=node
	var bodies := 0;var probes := 0
	for node in mv.get_children():
		if node is StaticBody3D:bodies+=1
	check(bodies==mv.footprint_reference.size(),"all mapped buildings have collision bodies")
	for id in mv.footprint_reference:
		var p: PackedVector2Array=mv.footprint_reference[id]
		if probes>=40:break
		if int(id)%37!=0:continue
		for edge in p.size():
			var a: Vector2=p[edge];var b: Vector2=p[(edge+1)%p.size()]
			if a.distance_to(b)<5:continue
			var at := (a+b)*0.5;var normal := Vector2(-(b-a).y,(b-a).x).normalized()
			var start := Vector3(at.x+normal.x*0.6,1.2,at.y+normal.y*0.6)
			var end := Vector3(at.x-normal.x*0.6,1.2,at.y-normal.y*0.6)
			var space: PhysicsDirectSpaceState3D= game.get_world_3d().direct_space_state
			check(not space.intersect_ray(PhysicsRayQueryParameters3D.create(start,end,1)).is_empty(),"mapped wall blocks first face")
			check(not space.intersect_ray(PhysicsRayQueryParameters3D.create(end,start,1)).is_empty(),"mapped wall blocks reverse face")
			probes+=1;break
	check(probes>=20,"test geographically distinct mapped wall faces")
	var total: int=game.world.tree_centers.size()
	for i in 30:
		var at: Vector3=game.world.center_at(float(i)*400)
		game.world.sweep_trees(at,at+Vector3(1,0,1),1.25)
		check(game.world.tree_candidates_last<maxi(30,total/10),"tree sweep checks local candidates rather than every tree")
	if not failed:print("PASS: garage reuse, thumb signs, calibrated tilt, pause/settings, recovery, ",probes," real two-sided wall probes and local tree sweeps")
	quit(1 if failed else 0)
