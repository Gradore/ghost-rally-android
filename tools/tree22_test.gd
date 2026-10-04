extends SceneTree
var world: TrackWorld
func _initialize() -> void:call_deferred("run_test")
func run_test() -> void:
	world=TrackWorld.new();root.add_child(world);world.build(GameData.TRACKS[16])
	var paths: Array=[]
	for i in 400:
		var at: Vector3=world.center_at(float(i)*35)+Vector3(float(i%9)-4,0,float(i%7)-3)
		paths.append([at,at+Vector3(float(i%11)-5,0,float(i%13)-6)])
	var checked := 0
	for p in paths:
		var old: Dictionary=reference_sweep(p[0],p[1],1.25)
		var now: Dictionary=world.sweep_trees(p[0],p[1],1.25)
		assert(old.is_empty()==now.is_empty(),"local broad phase preserves tree hits")
		if not old.is_empty():
			assert(old.tree_index==now.tree_index and old.position.distance_to(now.position)<0.0001,"same earliest swept tree hit")
		checked+=world.tree_candidates_last
	var start := Time.get_ticks_usec()
	for p in paths:reference_sweep(p[0],p[1],1.25)
	var old_us := Time.get_ticks_usec()-start
	start=Time.get_ticks_usec()
	for p in paths:world.sweep_trees(p[0],p[1],1.25)
	var new_us := Time.get_ticks_usec()-start
	print("PASS: 400 sweeps equivalent; trees=",world.tree_centers.size(),"; mean candidates=",float(checked)/400,"; reference=",old_us," us; indexed=",new_us," us")
	quit()
func reference_sweep(from: Vector3, to: Vector3, car_radius: float) -> Dictionary:
	var start := Vector2(from.x,from.z)
	var end := Vector2(to.x,to.z)
	var motion := end-start
	var length_squared := motion.length_squared()
	var earliest := 2.0
	var result := {}
	for i in world.tree_centers.size():
		var center := world.tree_centers[i]
		var radius := world.tree_radii[i]+car_radius
		if start.distance_squared_to(center)>pow(radius+motion.length()+1.0,2.0): continue
		var t := clampf((center-start).dot(motion)/maxf(length_squared,0.0001),0.0,1.0)
		if start.lerp(end,t).distance_squared_to(center)>radius*radius: continue
		var relative := start-center
		var entry := t
		if length_squared>0.0001:
			var b := relative.dot(motion)
			var disc := b*b-length_squared*(relative.length_squared()-radius*radius)
			if disc>=0.0: entry=clampf((-b-sqrt(disc))/length_squared,0.0,1.0)
		if entry>=earliest: continue
		var at := start.lerp(end,entry)
		var normal := (at-center).normalized()
		if normal.length_squared()<0.01: normal=(start-center).normalized()
		if normal.length_squared()<0.01: normal=Vector2(1,0)
		earliest=entry
		result={"position":center+normal*(radius+0.04),"normal":normal,"tree_index":i}
	return result

