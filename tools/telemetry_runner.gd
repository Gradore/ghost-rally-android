extends SceneTree
const Model=preload("res://scripts/vehicle_dynamics.gd")
const Data=preload("res://scripts/game_data.gd")
func _initialize() -> void:
	var file := FileAccess.open("../outputs/GhostRally-0.13.0-telemetry.csv",FileAccess.WRITE)
	file.store_line("time_s,speed_mps,rpm,gear,boost,fl_load_n,fr_load_n,rl_load_n,rr_load_n,fl_kappa,fr_kappa,rl_kappa,rr_kappa,body_height_m,pitch_rad,roll_rad")
	var model := Model.new();var v := Vector2.ZERO;var yaw := 0.0
	var setup := {"gearing":0.0,"suspension":0.0,"brake_bias":0.0};var upgrades := {"engine":0,"handling":0,"brakes":0}
	var began := Time.get_ticks_usec()
	for i in 60*20:
		var result: Dictionary=model.step(v,yaw,0,1 if i<60*15 else 0,0 if i<60*15 else 1,false,false,Data.CARS[10],setup,upgrades,true,true,1.0/60)
		v=result.velocity;yaw=result.yaw
		if i%6==0:
			var values: Array=[float(i+1)/60,v.length(),model.rpm,model.gear,model.turbo_boost]
			for w in model.wheels:values.append(w.load)
			for w in model.wheels:values.append(w.kappa)
			values.append_array([model.suspension.height,model.suspension.pitch,model.suspension.roll])
			file.store_csv_line(PackedStringArray(values.map(func(value):return str(value))))
	file.close()
	print("BENCH: ",model.ticks," ticks; ",(Time.get_ticks_usec()-began)/1000000.0," s desktop CPU; not a phone benchmark")
	quit()
