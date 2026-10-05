extends SceneTree
const Driving=preload("res://scripts/input/driving_input30.gd")
var failed := false
func check(ok: bool,msg: String) -> void:
	if not ok:failed=true;push_error(msg)
func _initialize() -> void:call_deferred("run_test")
func run_test() -> void:
	for value in [-1.0,-0.5,-0.1,0.0,0.1,0.5,1.0]:
		check(absf(Driving.axis(value,.12)+Driving.axis(-value,.12))<.0001,"symmetric stick mapping")
	check(Driving.axis(.1,.12)==0 and Driving.axis(-1,.12)==-1 and Driving.axis(1,.12)==1,"drift suppressed without losing full lock")
	check(Driving.axis(NAN,.12)==0,"invalid sensor value neutralizes")
	var slow=preload("res://scripts/input/mobile_steering.gd").new()
	var fast=preload("res://scripts/input/mobile_steering.gd").new()
	for i in 6:
		slow.step(1,20,1.0/60,.6);fast.step(1,20,1.0/60,1.6)
	check(fast.value>slow.value and fast.value<1,"response setting changes rise time without overshoot")
	var coarse=preload("res://scripts/input/mobile_steering.gd").new()
	var fine=preload("res://scripts/input/mobile_steering.gd").new()
	for i in 30:coarse.step(1,20,1.0/30,.6)
	for i in 120:fine.step(1,20,1.0/120,.6)
	check(absf(coarse.value-fine.value)<.0001,"configured steering remains rate invariant")
	change_scene_to_file("res://scenes/main.tscn")
	for i in 4:await process_frame
	var game := current_scene;var screen: Vector2=game.get_viewport().get_visible_rect().size
	game.save.casual=true;game.save.pedal_mode="joystick";game.save.control_mode="wheel";game.save.sensitivity=1
	var anchor := screen*Vector2(.85,.85)
	game.touch_anchor={0:anchor};game.touch={0:anchor};game.get_controls()
	check(game.throttle==0 and game.brake==0,"intentional neutral joystick overrides automatic throttle")
	game.touch[0]=anchor-screen*Vector2(0,.045);game.get_controls()
	check(game.throttle>.4 and game.throttle<.6,"automatic throttle preserves half analogue input")
	game.touch.clear();game.touch_anchor.clear();game.get_controls()
	check(game.throttle==1,"auto throttle resumes on pedal release")
	game.save.casual=false;game.save.thumb_travel=.08;game.save.steering_deadzone=.1
	anchor=screen*Vector2(.15,.85);game.touch_anchor={0:anchor};game.touch={0:anchor+screen*Vector2(.004,0)};game.get_controls()
	check(game.steer==0,"thumb neutral filters finger jitter")
	game.touch[0]=anchor+screen*Vector2(.08,0);game.get_controls();check(game.steer>.999,"configured thumb travel reaches full lock")
	game.touch.clear();game.touch_anchor.clear()
	var motion := InputEventJoypadMotion.new();motion.device=7;motion.axis=JOY_AXIS_LEFT_X;motion.axis_value=-.55;Input.parse_input_event(motion)
	var gas := InputEventJoypadMotion.new();gas.device=7;gas.axis=JOY_AXIS_TRIGGER_RIGHT;gas.axis_value=.5;Input.parse_input_event(gas)
	await process_frame
	var pad := Driving.gamepad(7,.12)
	check(pad.steer<-.4 and pad.throttle>.45 and pad.throttle<.55,"mapped controller adapter reads synthetic analog axes")
	gas.axis_value=0;Input.parse_input_event(gas);await process_frame
	check(Driving.gamepad(7,.12).throttle==0,"neutral trigger remains neutral")
	game.settings_tab=4;game.show_settings();await process_frame
	check(game.state=="settings","new input tab builds")
	if not failed:print("PASS: adjustable thumb range, jitter suppression, analogue auto-gas override, synthetic gamepad axes and input settings")
	quit(1 if failed else 0)
