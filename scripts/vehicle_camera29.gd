extends RefCounted
# Adapted from M.A.V.S. Cam_Holder.gd (Millu30, MIT).
# License and modifications: third_party/mavs29/LICENSE.txt, NOTICE.txt.
# Render-only; never changes native fixed-tick vehicle state.
var target_yaw := 0.0
var target_pitch := 0.0
var yaw := 0.0
var pitch := 0.0
var idle := 0.0
var reversing := false
var reverse_angle := 0.0
func reset() -> void:
	target_yaw=0;target_pitch=0;yaw=0;pitch=0;idle=0;reversing=false;reverse_angle=0
func update(delta: float, look: Vector2, forward_speed: float) -> void:
	if delta<=0:return
	if forward_speed< -1.2:reversing=true
	elif forward_speed>1.2:reversing=false
	if look.length()>0.05:
		idle=0.0
		target_yaw=wrapf(target_yaw-look.x*2.0*delta,-PI,PI)
		target_pitch=clampf(target_pitch+look.y*2.0*delta,-deg_to_rad(20),deg_to_rad(20))
	else:
		idle+=delta
		if idle>1.0 and absf(forward_speed)>1.0:
			var recenter := 1.0-exp(-2.0*delta)
			target_yaw=lerp_angle(target_yaw,0.0,recenter)
			target_pitch=lerpf(target_pitch,0.0,recenter)
	yaw=lerp_angle(yaw,target_yaw,1.0-exp(-5.0*delta))
	pitch=lerpf(pitch,target_pitch,1.0-exp(-2.0*delta))
	reverse_angle=lerp_angle(reverse_angle,PI if reversing else 0.0,1.0-exp(-5.0*delta))
func angles() -> Vector2:return Vector2(yaw+reverse_angle,pitch)
static func read_look_input() -> Vector2:
	var look := Vector2.ZERO
	if not Input.get_connected_joypads().is_empty():look=Vector2(Input.get_joy_axis(Input.get_connected_joypads()[0],JOY_AXIS_RIGHT_X),Input.get_joy_axis(Input.get_connected_joypads()[0],JOY_AXIS_RIGHT_Y))
	look.x+=float(Input.is_physical_key_pressed(KEY_KP_6))-float(Input.is_physical_key_pressed(KEY_KP_4))
	look.y+=float(Input.is_physical_key_pressed(KEY_KP_8))-float(Input.is_physical_key_pressed(KEY_KP_2))
	return look.limit_length(1.0)
