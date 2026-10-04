extends SceneTree
const Model=preload("res://scripts/vehicle_dynamics.gd")
const Data=preload("res://scripts/game_data.gd")
var failed := false
func check(ok: bool, msg: String) -> void:
	if not ok:failed=true;push_error(msg)
func _initialize() -> void:
	var cfg: Dictionary=Data.CARS[10]
	var setup := {"gearing":0.0,"suspension":0.0,"brake_bias":0.0}
	var upgrades := {"engine":0,"handling":0,"brakes":0}
	for hz in [240,720]:
		var model := Model.new();model.set_tick_hz(hz)
		var v := Vector2.ZERO;var yaw := 0.0;var acceleration := 0.0
		for i in 150*60:
			var r: Dictionary=model.step(v,yaw,0,1,0,false,false,cfg,setup,upgrades,false,true,1.0/60)
			v=r.velocity;yaw=r.yaw
			if v.length()*3.6>=100 and acceleration==0:acceleration=float(i+1)/60
		check(acceleration>=10.2 and acceleration<=10.8,"stock Lovo 0-100 calibration")
		check(absf(v.length()*3.6-185)<2.0,"stock Lovo maximum speed calibration")
		print("Lovo ",hz," Hz: 0-100=",acceleration," s; max=",v.length()*3.6," km/h")
	for initial_speed in [3.0,6.0,9.0]:
		var model := Model.new();var v := Vector2(0,-initial_speed);var yaw := 0.0;var worst := 0.0
		for i in 90:
			var r: Dictionary=model.step(v,yaw,-0.5,0.15,0,false,false,cfg,setup,upgrades,false,true,1.0/60)
			v=r.velocity;yaw=r.yaw
			worst=maxf(worst,absf(v.dot(Vector2(cos(yaw),-sin(yaw)))))
		check(yaw>0,"left thumb turns actual vehicle left")
		check(worst<2.1,"low speed corner has bounded lateral slide")
		print("Low-speed ",initial_speed*3.6," km/h: max lateral=",worst)
	if not failed:print("PASS: stock performance and low-speed left corner grip")
	quit(1 if failed else 0)
