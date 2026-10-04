extends SceneTree
const Model = preload("res://scripts/vehicle_dynamics.gd")
const Data = preload("res://scripts/game_data.gd")
var failed := false
func check(ok: bool, message: String) -> void:
	if not ok: failed=true;printerr("FAIL: "+message)
func _initialize() -> void:
	var cfg: Dictionary=Data.CARS[10]
	var setup := {"gearing":0.0,"suspension":0.0,"brake_bias":0.0}
	var stock := {"engine":0,"handling":0,"brakes":0}
	var model := Model.new()
	var v := Vector2.ZERO
	var yaw := 0.0
	for i in 600:
		var r: Dictionary=model.step(v,yaw,0,1,0,false,false,cfg,setup,stock,true,true,1.0/60)
		v=r.velocity;yaw=r.yaw
	check(v.length()>15 and v.length()<35,"VOC 0–10 s acceleration implausible")
	check(absf(yaw)<0.001 and absf(v.x)<0.001,"straight-line yaw drift")
	var initial_speed := v.length()
	for i in 180:
		var r: Dictionary=model.step(v,yaw,0,0,1,false,false,cfg,setup,stock,true,true,1.0/60)
		v=r.velocity;yaw=r.yaw
	check(v.length()<initial_speed*0.4,"brake fails to slow car")
	for hz in [30,60,120]:
		model=Model.new();v=Vector2(0,-20);yaw=0.0
		for i in hz*8:
			var r: Dictionary=model.step(v,yaw,0.5,0.4,0,false,false,cfg,setup,stock,true,true,1.0/float(hz))
			v=r.velocity;yaw=r.yaw
			check(is_finite(v.x) and is_finite(v.y) and is_finite(yaw),"unstable corner integration")
		check(yaw<0,"right steering turns wrong way")
	model=Model.new();v=Vector2.ZERO;yaw=0
	for i in 120:
		var r: Dictionary=model.step(v,yaw,0,0,1,false,true,cfg,setup,stock,true,true,1.0/60)
		v=r.velocity;yaw=r.yaw
	check(v.y>1 and v.length()<=8.1,"reverse fails")
	var a := Model.new();var b := Model.new()
	var boosted := {"engine":3,"handling":3,"brakes":3}
	var ra: Dictionary=a.step(Vector2(0,-12),0,0.4,1,0,false,false,cfg,setup,stock,true,true,1.0/60)
	var rb: Dictionary=b.step(Vector2(0,-12),0,0.4,1,0,false,false,cfg,setup,boosted,true,true,1.0/60)
	check(ra.velocity.is_equal_approx(rb.velocity),"VOC allows power upgrade")
	if not failed:print("PASS: acceleration, braking, reverse, stable corner integration and locked VOC upgrades")
	quit(1 if failed else 0)
