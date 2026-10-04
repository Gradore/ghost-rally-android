extends SceneTree
var test_failed := false

func _initialize() -> void:
	call_deferred("run_tests")

func fail(message: String) -> void:
	printerr("FAIL: "+message)
	test_failed = true

func run_tests() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	for i in 3: await process_frame
	var game := current_scene
	if game.Data.CARS.size()!=12: fail("expected twelve cars")
	var drive_count := {"FWD":0,"RWD":0,"AWD":0}
	for cfg in game.Data.CARS: drive_count[cfg.drive]+=1
	if drive_count!={"FWD":3,"RWD":4,"AWD":5}: fail("drive layout incorrect")
	game.active_car=0;game.active_track=0
	game.start_race()
	game.countdown=-1.0
	game.throttle=1.0
	var start_position: Vector3=game.car.position
	for i in 300: game.update_vehicle(1.0/60.0)
	print("Measured speed after 5 seconds: ",game.speed*3.6," km/h; road offset ",game.world.lateral_offset(game.car.position))
	if game.car.position.distance_to(start_position) < 30.0: fail("Car did not move forward")
	if game.speed < 12.0 or game.speed > 30.0: fail("Acceleration too weak")
	var z_before: float=game.car.position.z
	game.throttle=0.0
	game.brake=1.0
	for i in 120: game.update_vehicle(1.0/60.0)
	if game.speed > 7.0: fail("Braking too weak")
	game.build_world()
	game.velocity=Vector2.ZERO
	game.reverse_engaged=false
	game.throttle=0.0
	game.brake=1.0
	for i in 60: game.update_vehicle(1.0/60.0)
	var reverse_direction := Vector2(-sin(game.yaw),-cos(game.yaw))
	if not game.reverse_engaged or game.velocity.dot(reverse_direction)>-1.0: fail("Brake at standstill did not engage reverse")
	game.build_world()
	game.velocity=Vector2.ZERO
	game.reverse_engaged=false
	game.throttle=1.0
	game.brake=0.0
	game.steer=1.0
	for i in 75: game.update_vehicle(1.0/60.0)
	print("Steering displacement: ",game.car.position.x," yaw ",game.yaw)
	if game.yaw > -0.05: fail("Right steering did not turn right")
	game.build_world()
	game.velocity=Vector2(-sin(game.yaw),-cos(game.yaw))*42.0
	game.throttle=0.0
	game.steer=1.0
	var yaw_before: float=game.yaw
	game.update_vehicle(1.0/60.0)
	var yaw_step := absf(wrapf(game.yaw-yaw_before,-PI,PI))
	print("High-speed yaw step: ",yaw_step)
	if yaw_step<0.0 or yaw_step>0.01: fail("High-speed steering exceeds grip limit")
	var length: float=game.world.track.length
	game.car.position=game.world.center_at(length/3.0+10.0)
	game.check_progress()
	if game.checkpoint!=1: fail("First checkpoint missed")
	game.car.position=game.world.center_at(length*2.0/3.0+10.0)
	game.check_progress()
	if game.checkpoint!=2: fail("Second checkpoint missed")
	if not test_failed: print("PASS: twelve cars, physical acceleration, braking, steering, ordered checkpoints; brake start z=",z_before)
	quit(1 if test_failed else 0)
