extends RefCounted
class_name VehicleDynamics

const Tyre = preload("res://scripts/sim/tyre_model.gd")
const Differential = preload("res://scripts/sim/differential.gd")
const Suspension = preload("res://scripts/sim/suspension.gd")
var suspension = Suspension.new()
var wheel_ground := [0.0,0.0,0.0,0.0]
const H := 1.0/720.0
var tick_hz := 720
var tick_dt := H
const RATIOS := [3.71,2.16,1.37,1.0,0.82]
var yaw_rate := 0.0
var longitudinal_accel := 0.0
var lateral_accel := 0.0
var rpm := 950.0
var gear := 1
var shift_remaining := 0.0
var steering_angle := 0.0
var front_slip := 0.0
var rear_slip := 0.0
var turbo_boost := 0.0
var ticks := 0
var accumulator := 0.0
var wheels: Array[Dictionary] = []
var wheel_contacts := [true,true,true,true]
var wheel_grip := [1.0,1.0,1.0,1.0]
var vehicle := {}
var surfaces := {}
var vehicle_id := ""
var initialized := false

func reset() -> void:
	yaw_rate=0;longitudinal_accel=0;lateral_accel=0;rpm=950;gear=1
	shift_remaining=0;steering_angle=0;front_slip=0;rear_slip=0;turbo_boost=0
	ticks=0;accumulator=0;initialized=false;vehicle_id="";wheels.clear()
	suspension=Suspension.new();wheel_ground=[0.0,0.0,0.0,0.0]
	wheel_contacts=[true,true,true,true];wheel_grip=[1.0,1.0,1.0,1.0]

func _configure(cfg: Dictionary, speed: float) -> void:
	vehicle_id=str(cfg.id)
	var path := "res://config/vehicles/"+vehicle_id+".json"
	if FileAccess.file_exists(path):vehicle=JSON.parse_string(FileAccess.get_file_as_string(path))
	else:
		# ASSUMPTION: provisional generic tune for existing fictional garage cars.
		var torque := float(cfg.power)*735.499/(5600.0*TAU/60.0)
		vehicle={"mass_kg":cfg.mass,"wheelbase_m":cfg.get("wheelbase",2.6),"track_m":1.48,"cg_height_m":0.52,
			"front_fraction":0.59 if cfg.drive=="FWD" else 0.53,"wheel_radius_m":cfg.get("wheel_radius",0.31),
			"wheel_mass_kg":20.0,"wheel_inertia_kgm2":1.2,"ratios":RATIOS,"final_drive":4.1,"shift_up_rpm":6100,
			"redline_rpm":6500,"torque_curve_nm":[[900,torque*0.60],[3800,torque*1.1],[5600,torque],[6500,torque*0.72]],
			"turbo":true,"turbo_spool_s":0.50,"turbo_decay_s":0.20,"turbo_gain":0.35,
			"diff":{"type":"lsd","preload_nm":35,"power_lock":0.35,"coast_lock":0.15,"damping":8},"awd_front_fraction":0.45,
			"tyre_pressure_pa":200000,"tyre_initial_temperature_k":293.15}
	surfaces=JSON.parse_string(FileAccess.get_file_as_string("res://config/surfaces/surfaces.json"))
	wheels.clear()
	for i in 4:
		wheels.append({"abs_pressure":1.0,"omega":speed/float(vehicle.wheel_radius_m),"spin":0.0,"load":0.0,"kappa":0.0,"alpha":0.0,
			"force":Vector2.ZERO,"temperature_k":float(vehicle.tyre_initial_temperature_k),"pressure_pa":float(vehicle.tyre_pressure_pa),
			"mass_kg":float(vehicle.wheel_mass_kg),"inertia_kgm2":float(vehicle.wheel_inertia_kgm2)})
	suspension.configure(vehicle,wheel_ground)
	initialized=true

static func torque_at(curve: Array, engine_rpm: float) -> float:
	if engine_rpm<=float(curve[0][0]):return float(curve[0][1])
	for i in range(curve.size()-1):
		if engine_rpm<=float(curve[i+1][0]):
			return lerpf(float(curve[i][1]),float(curve[i+1][1]),(engine_rpm-float(curve[i][0]))/(float(curve[i+1][0])-float(curve[i][0])))
	return float(curve[-1][1])

func step(velocity: Vector2, yaw: float, steering: float, throttle: float,
		brake: float, handbrake: bool, reverse: bool, cfg: Dictionary,
		setup: Dictionary, upgrades: Dictionary, gravel: bool, on_road: bool, dt: float) -> Dictionary:
	if not initialized or vehicle_id!=str(cfg.id):_configure(cfg,velocity.dot(Vector2(-sin(yaw),-cos(yaw))))
	# Preserve the fractional tick. This produces identical tick sequences at 30/60/120 Hz.
	accumulator+=clampf(dt,0.0,0.25)
	var lateral := 0.0
	var displacement := Vector2.ZERO
	while accumulator+1e-10>=tick_dt:
		var r := _tick(velocity,yaw,steering,throttle,brake,handbrake,reverse,cfg,setup,upgrades,gravel,on_road)
		velocity=r.velocity;yaw=r.yaw;lateral=r.lateral
		displacement+=velocity*tick_dt
		accumulator-=tick_dt;ticks+=1
	return {"velocity":velocity,"yaw":yaw,"lateral":lateral,"displacement":displacement,"ticks":ticks}

func _tick(velocity: Vector2,yaw: float,steering: float,throttle: float,brake: float,handbrake: bool,reverse: bool,
		cfg: Dictionary,setup: Dictionary,upgrades: Dictionary,gravel: bool,on_road: bool) -> Dictionary:
	var forward := Vector2(-sin(yaw),-cos(yaw));var right := Vector2(cos(yaw),-sin(yaw))
	var u := velocity.dot(forward);var v := velocity.dot(right)
	var mass := float(vehicle.mass_kg);var wb := float(vehicle.wheelbase_m);var track := float(vehicle.track_m)
	var fraction := float(vehicle.front_fraction);var a := wb*(1-fraction);var b := wb*fraction
	var radius := float(vehicle.wheel_radius_m)
	var mechanical_angle := deg_to_rad(float(vehicle.get("steering_lock_degrees",37.0)))
	var target_angle := clampf(steering,-1,1)*mechanical_angle
	if setup.get("steering_assist",false) and velocity.length()>18.0 and not handbrake:
		# ASSUMPTION: controllable range near available lateral acceleration, not a yaw force.
		var lateral_limit := 6.5 if gravel else 9.5
		var range_angle := maxf(0.085,atan(wb*lateral_limit*1.55/maxf(velocity.length_squared(),1.0)))
		var blend := smoothstep(18.0,32.0,velocity.length())
		target_angle=steering*lerpf(mechanical_angle,minf(mechanical_angle,range_angle),blend)
	steering_angle=move_toward(steering_angle,target_angle,tick_dt*float(vehicle.get("steering_rate_rad_s",4.8)))
	var surface: Dictionary=surfaces["grass" if not on_road else "gravel" if gravel else "tarmac_dry"]
	var locked_spec := bool(cfg.get("voc",false))
	var upgrade_grip := 1.0 if locked_spec else 1.0+float(upgrades.handling)*0.025
	suspension.tick(tick_dt,wheel_ground,wheel_contacts,longitudinal_accel,lateral_accel,float(setup.suspension))
	var ratios: Array=vehicle.ratios
	var final_drive := float(vehicle.final_drive)*(1+float(setup.gearing)*0.08)
	var driven_omega := (float(wheels[0].omega)+float(wheels[1].omega))*0.5 if cfg.drive=="FWD" else (float(wheels[2].omega)+float(wheels[3].omega))*0.5
	if cfg.drive=="AWD":driven_omega=(float(wheels[0].omega)+float(wheels[1].omega)+float(wheels[2].omega)+float(wheels[3].omega))*0.25
	var ratio := float(ratios[gear-1])*final_drive
	rpm=maxf(950,absf(driven_omega)*ratio*60/TAU)
	shift_remaining=maxf(0,shift_remaining-tick_dt)
	if shift_remaining==0:
		if rpm>float(vehicle.shift_up_rpm) and gear<ratios.size() and absf(u)>4.0 and absf(driven_omega*radius-u)<maxf(3.0,absf(u)*0.45):gear+=1;shift_remaining=0.20
		elif rpm<2100 and gear>1:gear-=1;shift_remaining=0.16
	var boost_target := throttle*clampf((rpm-1400)/3000,0,1) if bool(vehicle.turbo) else 0.0
	var spool := float(vehicle.turbo_spool_s) if boost_target>turbo_boost else float(vehicle.turbo_decay_s)
	turbo_boost+=(boost_target-turbo_boost)*(1-exp(-tick_dt/maxf(spool,0.01)))
	var engine_torque := torque_at(vehicle.torque_curve_nm,rpm)
	if not locked_spec:engine_torque*=1+float(upgrades.engine)*0.09
	engine_torque*=(1+float(vehicle.turbo_gain)*turbo_boost)/(1+float(vehicle.turbo_gain))
	var drive := (throttle*engine_torque-(1-throttle)*18.0*clampf(u,0,1))*ratio*float(vehicle.get("driveline_efficiency",0.87))
	if setup.get("traction_assist",false) and not reverse and absf(u)>2.0:
		var drive_slip := maxf(0.0,(absf(driven_omega)*radius-absf(u))/maxf(absf(u),3.0))
		drive*=lerpf(1.0,0.22,smoothstep(0.18,0.60,drive_slip))
	if shift_remaining>0:drive*=0.05
	if rpm>float(vehicle.redline_rpm):drive=0
	if reverse:drive=-brake*engine_torque*float(ratios[0])*final_drive*0.60
	var front_torque := drive if cfg.drive=="FWD" else 0.0;var rear_torque := drive if cfg.drive=="RWD" else 0.0
	if cfg.drive=="AWD":
		var split := float(vehicle.awd_front_fraction)
		var center_limit := float(vehicle.get("center_preload_nm",60.0))+absf(drive)*float(vehicle.get("center_power_lock",0.3))*0.5
		var center_transfer := clampf(((float(wheels[0].omega)+float(wheels[1].omega))-(float(wheels[2].omega)+float(wheels[3].omega)))*4.0,-center_limit,center_limit)
		front_torque=drive*split-center_transfer;rear_torque=drive*(1-split)+center_transfer
	var ft := Differential.split(front_torque,wheels[0].omega,wheels[1].omega,vehicle.diff)
	var rt := Differential.split(rear_torque,wheels[2].omega,wheels[3].omega,vehicle.diff)
	var drive_torques := [ft.x,ft.y,rt.x,rt.y]
	var bias := clampf(0.64+float(setup.brake_bias)*0.08,0.5,0.8)
	var total := Vector2.ZERO;var moment := 0.0;var normal_total := 0.0
	for i in 4:
		var wheel: Dictionary=wheels[i];var front := i<2;var side := -1.0 if i%2==0 else 1.0
		var longitudinal := a if front else -b;var x := side*track*0.5
		var load := float(suspension.hubs[i].normal)
		if not wheel_contacts[i]:load=0.0
		wheel.load=load;normal_total+=load
		var delta := 0.0
		if front and absf(steering_angle)>0.001:
			var turn_radius := wb/tan(absf(steering_angle))
			delta=signf(steering_angle)*atan(wb/maxf(0.5,turn_radius-side*signf(steering_angle)*track*0.5))
		wheel["steer_angle"]=delta
		var cs := cos(delta);var sn := sin(delta)
		var hub_u := u+yaw_rate*x;var hub_v := v-yaw_rate*longitudinal
		var tyre_u := hub_u*cs+hub_v*sn;var tyre_v := -hub_u*sn+hub_v*cs
		var kappa := clampf((float(wheel.omega)*radius-tyre_u)/maxf(absf(tyre_u),2.0),-3.0,3.0)
		var alpha := atan2(tyre_v,maxf(absf(tyre_u),2.0))
		var relaxation_length := float(surface.get("brake_relaxation_m",0.12)) if brake>0.01 or handbrake else float(surface.relaxation_m)
		var relaxation := minf(1,tick_dt*maxf(absf(tyre_u),2)/relaxation_length)
		wheel.kappa=lerpf(wheel.kappa,kappa,relaxation);wheel.alpha=lerpf(wheel.alpha,alpha,relaxation)
		var grip := upgrade_grip*float(wheel_grip[i])*Tyre.thermal_grip(wheel.temperature_k,wheel.pressure_pa)
		# ASSUMPTION: mild load sensitivity relative to static quarter-car load.
		grip*=clampf(1.0-0.08*(load/(mass*9.81/4)-1),0.75,1.08)
		var fx := Tyre.magic(wheel.kappa,load,surface.longitudinal)*grip
		var fy := -Tyre.magic(wheel.alpha,load,surface.lateral)*grip
		var force := Tyre.combined(fx,fy,load*float(surface.longitudinal[2])*grip)
		wheel.force=force
		var brake_torque: float= (0 if reverse else brake)*mass*float(vehicle.get("brake_capacity_mps2",15.0))*radius*(bias if front else 1-bias)*0.5
		if setup.get("abs_assist",false) and not reverse and tyre_u>5.0 and brake>0.01 and load>1.0:
			var pressure_target := 0.10 if kappa< -0.16 else 1.0
			wheel.abs_pressure=move_toward(float(wheel.abs_pressure),pressure_target,tick_dt*(32.0 if pressure_target<0.5 else 10.0))
			brake_torque*=float(wheel.abs_pressure)
		else:wheel.abs_pressure=1.0
		if handbrake and not front:brake_torque+=2400
		var omega_before := float(wheel.omega)
		var brake_direction := signf(omega_before) if absf(omega_before)>0.01 else signf(tyre_u)
		wheel.omega+=(float(drive_torques[i])-force.x*radius-brake_torque*brake_direction)/float(wheel.inertia_kgm2)*tick_dt
		if brake_torque>absf(float(drive_torques[i])):
			if tyre_u>0:wheel.omega=maxf(0,wheel.omega)
			elif tyre_u<0:wheel.omega=minf(0,wheel.omega)
		wheel.omega=clampf(wheel.omega,-650,650);wheel.spin=fmod(wheel.spin+wheel.omega*tick_dt,TAU)
		var heat := absf(force.x*(omega_before*radius-tyre_u))+absf(force.y*tyre_v)
		wheel.temperature_k=clampf(wheel.temperature_k+(heat*0.35-(wheel.temperature_k-293.15)*14)/18000*tick_dt,273.15,500)
		var body_force := Vector2(force.x*cs-force.y*sn,force.x*sn+force.y*cs)
		total+=body_force;moment+=x*body_force.x-longitudinal*body_force.y
	front_slip=(float(wheels[0].alpha)+float(wheels[1].alpha))*0.5
	rear_slip=(float(wheels[2].alpha)+float(wheels[3].alpha))*0.5
	var drag := float(vehicle.get("drag_n_per_mps2",0.40))*u*absf(u)+normal_total*float(surface.rolling)*clampf(u,-1,1)
	longitudinal_accel=(total.x-drag)/mass;lateral_accel=total.y/mass
	var gradient: Vector2=setup.get("terrain_gradient",Vector2.ZERO)
	velocity+=(forward*longitudinal_accel+right*lateral_accel-gradient*9.81/(1+gradient.length_squared()))*tick_dt
	yaw_rate=clampf(yaw_rate+moment/(mass*wb*wb*0.26)*tick_dt,-2.5,2.5)
	if absf(u)<12.0 and not handbrake and normal_total>mass*9.81*0.5:
		# Blend low-speed tyre dynamics toward rolling contact; fade out before fast corners.
		var support := 1.0-smoothstep(5.0,12.0,absf(u))
		yaw_rate=lerpf(yaw_rate,-u*tan(steering_angle)/wb,minf(1,tick_dt*14*support))
		velocity-=right*v*minf(1,tick_dt*12*support)
	if not reverse and throttle<0.01 and velocity.length()<0.12:velocity=Vector2.ZERO;yaw_rate=0
	if reverse and velocity.dot(forward)<-8:velocity+=forward*(-8-velocity.dot(forward))
	return {"velocity":velocity,"yaw":yaw+yaw_rate*tick_dt,"lateral":v}

func _init() -> void:
	set_tick_hz(240 if OS.has_feature("android") else 720)

func set_tick_hz(hz: int) -> void:
	assert(hz in [240,360,720],"unsupported integration preset")
	tick_hz=hz;tick_dt=1.0/float(hz);accumulator=0.0
