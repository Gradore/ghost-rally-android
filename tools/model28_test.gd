extends SceneTree
const Visual=preload("res://scripts/external_vehicle.gd")
func _initialize() -> void:call_deferred("run_test")
func run_test() -> void:
	var original_config: Dictionary=GameData.CARS[10].duplicate();original_config.id="native_collider_fixture"
	var native := RallyCar.new();root.add_child(native);native.configure(original_config)
	var expected := Vector3.ZERO
	for child in native.get_children():
		if child is CollisionShape3D:expected=child.shape.size
	var car := RallyCar.new();root.add_child(car);car.configure(GameData.CARS[10])
	var data: Dictionary=car.imported_visual
	assert(not data.has("error") and data.get("articulated_wheels",false),"shipped user model must load and articulate four wheels")
	assert(data.triangles>20000 and data.triangles<60000,"actual processed car, bounded mobile geometry")
	assert(absf(data.length_m-4.87)<0.005,"model in metres")
	for child in car.get_children():
		if child is CollisionShape3D:assert(child.shape.size==expected,"user mesh cannot replace native collider")
	for i in 4:
		var wheel := Visual.find_named(car.wheel_spins[i],["wheel_fl","wheel_fr","wheel_rl","wheel_rr"][i])
		assert(wheel!=null and wheel.position.length()<0.001,"wheel origin retargeted to native axle")
		assert(Visual.bounds(wheel).size.y>0.6 and Visual.bounds(wheel).size.y<0.65,"317mm tyre radius retained")
	car.animate_car(1,0,0,0.016,0.55)
	car.update_wheel_visuals([{"spin":1.2,"steer_angle":0.55},{"spin":1.2,"steer_angle":0.55},{"spin":1.2,"steer_angle":0.55},{"spin":1.2,"steer_angle":0.55}])
	for spin in car.wheel_spins:assert(absf(spin.rotation.x+1.2)<0.0001)
	assert(absf(car.wheels[0].rotation.y+0.55)<0.0001,"imported front wheel steers")
	var lens := Visual.find_named(car.body,"Red rear lens")
	assert(lens is MeshInstance3D and lens.get_active_material(0)==car.rear_lamps,"imported lamps bind to per-car brake material")
	car.set_braking(true);assert(car.rear_lamps.emission_energy_multiplier>0.8)
	car.set_braking(false);assert(car.rear_lamps.emission_energy_multiplier<0.1)
	print("PASS: shipped Meshy model, triangle budget, metre fit, native collider, four centred rotating/steering wheels, live brake lamps")
	car.queue_free();native.queue_free();await process_frame;quit()
