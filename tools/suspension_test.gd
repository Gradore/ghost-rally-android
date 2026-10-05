extends SceneTree
const Model=preload("res://scripts/sim/suspension.gd")
var errors: Array[String]=[]
func check(ok: bool, message: String) -> void:
	if not ok:errors.append(message)
func _initialize() -> void:
	var cfg: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://config/vehicles/lovo940voc.json"))
	for hz in [240,360,720]:
		var s=Model.new();s.configure(cfg,[0,0,0,0])
		for i in hz*5:s.tick(1.0/hz,[0,0,0,0],[true,true,true,true],0,0)
		var total := 0.0
		for h in s.hubs:total+=float(h.normal)
		check(absf(total-float(cfg.mass_kg)*9.81)<1,"static normal force equals total weight at %d Hz"%hz)
		check(absf(s.height-s.ride_height)<0.001 and absf(s.roll)<0.001 and absf(s.pitch)<0.001,"flat static equilibrium")
		# Acceleration raises nose; braking reverses load transfer.
		for i in hz*3:s.tick(1.0/hz,[0,0,0,0],[true,true,true,true],4,0)
		check(s.pitch>0 and s.hubs[0].normal<s.hubs[2].normal,"acceleration transfers weight rearward")
		for i in hz*3:s.tick(1.0/hz,[0,0,0,0],[true,true,true,true],-6,0)
		check(s.pitch<0 and s.hubs[0].normal>s.hubs[2].normal,"braking transfers weight forward")
		s.configure(cfg,[0,0,0,0])
		for i in hz/5:s.tick(1.0/hz,[0.09,0,0,0],[true,true,true,true],0,0)
		check(absf(float(s.hubs[0].y)-float(s.hubs[1].y))>0.015,"single wheel bump moves independent unsprung mass")
		check(absf(s.roll)>0.0001 or absf(s.pitch)>0.0001,"bump reacts on body")
		for i in hz*6:s.tick(1.0/hz,[0,0,0,0],[true,true,true,true],0,0)
		check(absf(s.speed)<0.002 and absf(s.roll_rate)<0.002,"damping settles bump")
		s.configure(cfg,[0,0,0,0]);s.height+=0.7
		for h in s.hubs:h.y+=0.7
		for i in hz/10:s.tick(1.0/hz,[0,0,0,0],[true,true,true,true],0,0)
		for h in s.hubs:check(h.normal==0,"airborne wheel has no tensile ground force")
		check(s.speed < -0.9,"gravity accelerates airborne body")
		for i in hz*4:s.tick(1.0/hz,[0,0,0,0],[true,true,true,true],0,0)
		check(is_finite(s.height) and absf(s.height-s.ride_height)<0.01,"drop lands and settles without exploding")
	if not errors.is_empty():
		for e in errors:push_error(e)
		quit(1)
	else:print("PASS: 240/360/720 Hz static support, acceleration/braking transfer, independent bump, damping, flight and landing");quit()
