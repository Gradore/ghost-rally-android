extends SceneTree
const Model=preload("res://scripts/vehicle_dynamics.gd")
const Data=preload("res://scripts/game_data.gd")
var failed := false
func check(ok: bool,msg: String) -> void:
	if not ok:failed=true;push_error(msg)
func stop(pedal: float, hz: int, gravel: bool=false) -> Dictionary:
	var model := Model.new();model.set_tick_hz(hz);var v := Vector2(0,-20);var yaw := 0.0;var distance := 0.0;var bite := 0.0
	for i in 1200:
		var r: Dictionary=model.step(v,yaw,0,0,pedal,false,false,Data.CARS[10],{"gearing":0.0,"suspension":0.0,"brake_bias":0.0,"abs_assist":true},{"engine":0,"handling":0,"brakes":0},gravel,true,1.0/60)
		v=r.velocity;yaw=r.yaw;distance+=r.displacement.length()
		if bite==0 and model.longitudinal_accel< -4: bite=float(i+1)/60
		if v.length()<0.12:break
	return {"distance":distance,"speed":v.length(),"bite":bite}
func _initialize() -> void:call_deferred("run_test")
func run_test() -> void:
	var full := stop(1.0,240);var half := stop(0.5,240);var quarter := stop(0.25,240);var high_tick := stop(1,720);var gravel := stop(1,240,true)
	print("Braking ",full," half ",half," quarter ",quarter," 720Hz ",high_tick," gravel ",gravel)
	check(full.speed<0.12 and full.bite<=0.1,"full brake reaches useful deceleration within 100 ms and stops")
	check(quarter.distance>half.distance and half.distance>full.distance,"analogue braking has graduated stopping distance")
	check(absf(full.distance-high_tick.distance)<full.distance*0.03,"brake distance agrees across fixed integration presets")
	check(gravel.distance>full.distance,"gravel retains lower braking grip")
	for sign_steer in [-1.0,1.0]:
		var model := Model.new();var v := Vector2(0,-4);var yaw := 0.0
		for i in 30:
			var r: Dictionary=model.step(v,yaw,sign_steer,0.1,0,false,false,Data.CARS[10],{"gearing":0.0,"suspension":0.0,"brake_bias":0.0,"steering_assist":true},{"engine":0,"handling":0,"brakes":0},false,true,1.0/60)
			v=r.velocity;yaw=r.yaw
		check(absf(model.steering_angle)>deg_to_rad(35),"full road-wheel lock at town speed")
		var inside: int=0 if sign_steer<0 else 1;var outside: int=1-inside
		check(absf(model.wheels[inside].steer_angle)>absf(model.wheels[outside].steer_angle),"inside wheel has greater Ackermann angle")
		check(yaw*sign_steer<0,"turn direction remains correct")
	var hand := Model.new();var v := Vector2(0,-12);var yaw := 0.0
	for i in 12:
		var r: Dictionary=hand.step(v,yaw,0,0,0,true,false,Data.CARS[10],{"gearing":0.0,"suspension":0.0,"brake_bias":0.0},{"engine":0,"handling":0,"brakes":0},true,true,1.0/60)
		v=r.velocity;yaw=r.yaw
	check(absf(hand.wheels[2].omega)<1 and absf(hand.wheels[3].omega)<1 and absf(hand.wheels[0].omega)>10,"handbrake locks rear only")
	change_scene_to_file("res://scenes/main.tscn")
	for i in 4:await process_frame
	var game := current_scene;game.save.control_mode="wheel";game.save.pedal_mode="joystick";game.save.casual=false;game.save.sensitivity=1
	var screen: Vector2=game.get_viewport().get_visible_rect().size
	var anchor := screen*Vector2(0.85,0.85)
	game.touch_anchor={0:anchor};game.touch={0:anchor-screen*Vector2(0,0.045)};game.get_controls()
	check(game.throttle>0.4 and game.throttle<0.6 and game.brake==0,"half upward joystick travel gives analogue throttle")
	game.touch={0:anchor+screen*Vector2(0,0.09)};game.get_controls()
	check(game.brake>0.99 and game.throttle==0,"downward joystick travel gives full brake")
	game.touch_anchor[1]=screen*Vector2(0.15,0.83);game.touch[1]=screen*Vector2(0.10,0.83)
	game.touch_anchor[2]=screen*Vector2(0.86,0.66);game.touch[2]=game.touch_anchor[2];game.get_controls()
	check(game.steer<0 and game.brake>0.99 and game.handbrake,"three concurrent fingers steer, brake and pull handbrake")
	game.touch.clear();game.touch_anchor.clear();game.get_controls();check(game.brake==0 and game.throttle==0 and not game.handbrake,"release clears all pedals")
	game.brake=1;game.update_reverse(5);game.update_reverse(0)
	check(not game.reverse_engaged,"holding brake to a stop cannot launch reverse")
	game.brake=0;game.update_reverse(0);game.brake=1;game.update_reverse(0)
	check(game.reverse_engaged,"repressing brake at rest selects reverse")
	if not failed:print("PASS: braking response, analogue modulation, Ackermann, rear handbrake, multi-touch joystick, safe stop/reverse")
	quit(1 if failed else 0)
