extends SceneTree
const Orbit=preload("res://scripts/vehicle_camera29.gd")
const Visual=preload("res://scripts/external_vehicle.gd")
func _initialize() -> void:call_deferred("run_test")
func simulate(hz: int) -> Vector2:
	var camera := Orbit.new()
	for i in hz:camera.update(1.0/hz,Vector2.ZERO,-4.0)
	return camera.angles()
func run_test() -> void:
	assert(absf(wrapf(simulate(30).x-simulate(120).x,-PI,PI))<0.0001,"reverse camera smoothing is frame-rate invariant")
	var orbit := Orbit.new();orbit.update(.016,Vector2.ONE,-3.0)
	for i in 100:orbit.update(.016,Vector2(0,1),0)
	assert(absf(orbit.target_pitch)<=deg_to_rad(20)+.0001,"manual camera cannot flip over")
	orbit.update(.016,Vector2.ZERO,-.3);assert(orbit.reversing,"standstill retains reverse view without oscillation")
	orbit.update(.016,Vector2.ZERO,3.0);assert(not orbit.reversing)
	orbit.target_yaw=1.0;orbit.yaw=1.0;orbit.idle=2
	for i in 120:orbit.update(1.0/60,Vector2.ZERO,5.0)
	assert(absf(orbit.yaw)<.09,"orbit recenters after inactivity while driving")
	var addon := ConfigFile.new();assert(addon.load("res://addons/terrain_3d/plugin.cfg")==OK)
	assert(addon.get_value("plugin","version")=="1.0.2","requested Terrain3D release installed")
	assert(ClassDB.class_exists("Terrain3D"),"native extension loaded")
	var terrain=preload("res://scripts/lake_terrain.gd")
	var grass: Image=terrain.texture("res://assets/textures/terrain29/ground037_alb_ht.png").get_image()
	var bank: Image=terrain.atlas_tile(3).get_image()
	var normal: Image=terrain.texture("res://assets/nature/gravel_floor_nor_gl.jpg").get_image()
	assert(grass.get_format()==bank.get_format() and grass.get_format()==normal.get_format(),"Terrain3D layers use matching packed RGBA formats")
	var car := RallyCar.new();root.add_child(car);car.configure(GameData.CARS[10])
	assert(car.imported_visual.triangles<50000,"detailed complete car stays within mobile budget")
	var holder := Visual.find_named(car.body,"ImportedVisual");var data := Visual.inspect(holder)
	assert(data.meshes==1,"static car details merged, wheels are independent")
	for spin in car.wheel_spins:
		var wheel: MeshInstance3D=Visual.find_named(spin,["wheel_fl","wheel_fr","wheel_rl","wheel_rr"][car.wheel_spins.find(spin)])
		assert(wheel.mesh.get_surface_count()<=4,"bounded wheel material batches")
		var box := wheel.mesh.get_aabb();assert(box.size.x>.185 and box.size.x<.210,"195mm tyre width")
		assert(box.size.y>.630 and box.size.y<.641,"realistic tyre outer diameter")
		var unique_radii := {};var sidewall := false
		for s in wheel.mesh.get_surface_count():
			var arrays: Array=wheel.mesh.surface_get_arrays(s)
			for v in arrays[Mesh.ARRAY_VERTEX]:
				var r := Vector2(v.y,v.z).length()
				if absf(v.x)>.085 and r>.20 and r<.29:sidewall=true
				unique_radii[roundi(r*1000)]=true
		assert(sidewall and unique_radii.size()>12,"rounded sidewalls and tread replace flat discs")
	print("PASS: requested Terrain3D release, MAVS-derived camera invariance/reverse/recenter, bounded merged car, rounded 195/65R15 tyres")
	car.queue_free();await process_frame;quit()
