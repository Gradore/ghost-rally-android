extends SceneTree
const Model=preload("res://scripts/vehicle_dynamics.gd")
const Data=preload("res://scripts/game_data.gd")
func braking(enabled: bool) -> Dictionary:
	var model := Model.new();model.set_tick_hz(240);var v := Vector2(0,-25);var yaw := 0.0;var distance := 0.0;var locked := 0
	for i in 600:
		var r: Dictionary=model.step(v,yaw,0,0,1,false,false,Data.CARS[10],{"gearing":0.0,"suspension":0.0,"brake_bias":0.0,"abs_assist":enabled},{"engine":0,"handling":0,"brakes":0},false,true,1.0/60)
		v=r.velocity;yaw=r.yaw;distance+=r.displacement.length()
		if v.length()>5 and absf(float(model.wheels[0].kappa))>0.8:locked+=1
		if v.length()<0.15:break
	return {"distance":distance,"locked":locked,"speed":v.length()}
func traction(enabled: bool) -> Dictionary:
	var model := Model.new();model.set_tick_hz(240);var v := Vector2(0,-8);var yaw := 0.0;var slip := 0.0
	for i in 240:
		var r: Dictionary=model.step(v,yaw,0,1,0,false,false,Data.CARS[5],{"gearing":0.0,"suspension":0.0,"brake_bias":0.0,"traction_assist":enabled},{"engine":0,"handling":0,"brakes":0},true,true,1.0/60)
		v=r.velocity;yaw=r.yaw;slip+=absf(float(model.wheels[2].kappa))
	return {"slip":slip/240,"speed":v.length()}
func _initialize() -> void:
	var without := braking(false);var with_abs := braking(true)
	assert(with_abs.locked<without.locked/4 and with_abs.speed<0.15,"ABS releases sustained wheel lock and stops")
	assert(with_abs.distance<without.distance*1.05,"dry-tarmac ABS does not materially worsen stop")
	var open := traction(false);var controlled := traction(true)
	assert(controlled.slip<open.slip*0.65 and controlled.speed>=open.speed*0.9,"TC reduces wheelspin without bogging down")
	var model := Model.new();var v := Vector2(0,-30);var yaw := 0.0
	for i in 90:
		var r: Dictionary=model.step(v,yaw,-1,0.2,0,false,false,Data.CARS[10],{"gearing":0.0,"suspension":0.0,"brake_bias":0.0,"steering_assist":true},{"engine":0,"handling":0,"brakes":0},false,true,1.0/60)
		v=r.velocity;yaw=r.yaw
	print("Assist probe speed=",v.length()," angle=",model.steering_angle)
	assert(yaw>0 and absf(model.steering_angle)<0.45,"speed-sensitive assistance preserves direction and moderates angle")
	print("PASS: ABS stop ",with_abs.distance," m vs ",without.distance," m; locked ",with_abs.locked," vs ",without.locked,"; TC slip ",controlled.slip," vs ",open.slip,"; bounded high-speed steering")
	quit()
