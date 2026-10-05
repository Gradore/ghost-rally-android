extends SceneTree
const Model=preload("res://scripts/vehicle_dynamics.gd")
const Tyre=preload("res://scripts/sim/tyre_model.gd")
const Diff=preload("res://scripts/sim/differential.gd")
const Data=preload("res://scripts/game_data.gd")
var failed := false
var setup := {"gearing":0.0,"suspension":0.0,"brake_bias":0.0}
var upgrades := {"engine":0,"handling":0,"brakes":0}
func check(condition: bool,message: String) -> void:
	if not condition:failed=true;printerr("FAIL: "+message)
func run_case(hz: int,cfg: Dictionary,braking: bool = false,offroad: bool = false,physics_hz: int = 720) -> Dictionary:
	var model := Model.new();model.set_tick_hz(physics_hz);var velocity := Vector2(0,-20);var yaw := 0.0;var position := Vector2.ZERO
	for i in hz*4:
		var r: Dictionary=model.step(velocity,yaw,0.25 if not braking else 0,0.45 if not braking else 0,1 if braking else 0,false,false,cfg,setup,upgrades,true,not offroad,1.0/hz)
		velocity=r.velocity;yaw=r.yaw;position+=r.displacement
	return {"model":model,"velocity":velocity,"yaw":yaw,"position":position}
func _initialize() -> void:
	var coef := [10,1.9,1,0.97]
	check(Tyre.magic(0,3000,coef)==0,"nonzero static slip force")
	check(is_equal_approx(Tyre.magic(0.2,3000,coef),-Tyre.magic(-0.2,3000,coef)),"asymmetric tyre curve")
	check(Tyre.combined(2500,2500,3000).length()<=3000.001,"combined forces exceed friction capacity")
	check(Tyre.magic(0.2,0,coef)==0,"airborne tyre has force")
	check(Tyre.thermal_grip(333,200000)>Tyre.thermal_grip(450,260000),"thermal/pressure grip response")
	var split := Diff.split(800,90,30,{"type":"lsd","preload_nm":50,"power_lock":0.4})
	check(is_equal_approx(split.x+split.y,800) and split.y>split.x,"LSD torque balance/transfer")
	check(Diff.split(800,90,30,{"type":"open"}).is_equal_approx(Vector2(400,400)),"open diff is not equal torque")
	var baseline := run_case(60,Data.CARS[10])
	for hz in [30,120,144]:
		var result := run_case(hz,Data.CARS[10])
		check(result.model.ticks==2880,"wrong fixed tick count at "+str(hz))
		check(result.velocity.distance_to(baseline.velocity)<0.00001,"frame rate changes velocity")
		check(absf(result.yaw-baseline.yaw)<0.00001,"frame rate changes yaw")
		check(result.position.distance_to(baseline.position)<0.001,"frame partition displacement error exceeds one millimetre")
	for preset in [240,360]:
		var mobile := run_case(60,Data.CARS[10],false,false,preset)
		var partition := run_case(144,Data.CARS[10],false,false,preset)
		check(mobile.model.ticks==preset*4 and mobile.velocity.distance_to(partition.velocity)<0.00001,"mobile preset partition drift")
	var gravel_stop := run_case(60,Data.CARS[10],true)
	var grass_stop := run_case(60,Data.CARS[10],true,true)
	check(gravel_stop.position.length()<grass_stop.position.length(),"low grip should lengthen stopping distance")
	var turbo := Model.new();var v := Vector2(0,-15);var yaw := 0.0;var early := 0.0
	for i in 120:
		var r: Dictionary=turbo.step(v,yaw,0,1,0,false,false,Data.CARS[-1],setup,upgrades,true,true,1.0/60)
		v=r.velocity;yaw=r.yaw
		if i==5:early=turbo.turbo_boost
	check(early>0 and early<turbo.turbo_boost,"boost should spool rather than jump to full")
	check(baseline.model.turbo_boost==0,"naturally aspirated Volvo received turbo boost")
	check(turbo.wheels.size()==4,"four independent wheels missing")
	turbo.wheel_contacts[2]=false
	var omega := float(turbo.wheels[2].omega)
	var r: Dictionary=turbo.step(v,yaw,0,1,0,false,false,Data.CARS[-1],setup,upgrades,true,true,1.0/60)
	check(turbo.wheels[2].force==Vector2.ZERO and turbo.wheels[2].load==0,"airborne wheel contact force")
	check(turbo.wheels[2].mass_kg>0 and turbo.wheels[2].inertia_kgm2>0 and turbo.wheels[2].omega!=omega,"airborne wheel lost independent rotational dynamics")
	var split_grip := Model.new();v=Vector2(0,-10);yaw=0
	split_grip.step(v,yaw,0,0,0,false,false,Data.CARS[0],setup,upgrades,false,true,1.0/60)
	split_grip.wheel_grip[0]=0.2
	for i in 120:
		r=split_grip.step(v,yaw,0,1,0,false,false,Data.CARS[0],setup,upgrades,false,true,1.0/60);v=r.velocity;yaw=r.yaw
	check(absf(split_grip.wheels[0].omega-split_grip.wheels[1].omega)>0.1,"split grip wheels remain coupled rigidly")
	check(is_finite(yaw) and v.length()<80,"split grip unstable")
	var flight := Model.new()
	flight.step(Vector2(3,0),0,0,0,0,false,false,Data.CARS[10],setup,upgrades,true,true,0)
	flight.wheel_contacts=[false,false,false,false]
	var free: Dictionary=flight.step(Vector2(3,0),0,0,0,0,false,false,Data.CARS[10],setup,upgrades,true,true,1.0/60)
	check(absf(float(free.velocity.x)-3.0)<0.0001,"airborne lateral momentum lost to artificial ground damping")
	if not failed:print("PASS: 720 Hz at 30/60/120/144 Hz; MF/combined slip; braking grip; LSD; turbo lag; independent airborne/split-grip wheels")
	quit(1 if failed else 0)
