extends RefCounted
# Original input adapter. Godot's mapped trigger axes use 0..1, not -1..1.
static func axis(value: float, deadzone: float, curve: float=1.0) -> float:
	if not is_finite(value): return 0.0
	deadzone=clampf(deadzone,0.0,0.4)
	var magnitude := clampf((absf(value)-deadzone)/(1.0-deadzone),0.0,1.0)
	return signf(value)*pow(magnitude,clampf(curve,0.5,2.0))

static func gamepad(device: int, deadzone: float) -> Dictionary:
	return {
		"steer":axis(Input.get_joy_axis(device,JOY_AXIS_LEFT_X),deadzone),
		"throttle":clampf(Input.get_joy_axis(device,JOY_AXIS_TRIGGER_RIGHT),0.0,1.0),
		"brake":clampf(Input.get_joy_axis(device,JOY_AXIS_TRIGGER_LEFT),0.0,1.0),
		"handbrake":Input.is_joy_button_pressed(device,JOY_BUTTON_A)
	}
