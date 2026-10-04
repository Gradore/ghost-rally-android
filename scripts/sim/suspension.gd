extends RefCounted
# Reduced vertical model: body heave/pitch/roll + four unsprung masses.
# Angles are small-angle coordinates, NOT unrestricted 6-DOF rotation.
var height := 0.55
var speed := 0.0
var pitch := 0.0
var pitch_rate := 0.0
var roll := 0.0
var roll_rate := 0.0
var hubs: Array[Dictionary] = []
var mass := 1000.0
var unsprung := 20.0
var radius := 0.31
var ride_height := 0.55
var spring := 32000.0
var damper := 3200.0
var tyre_spring := 180000.0
var tyre_damper := 450.0
var antiroll := 10000.0
var cg := 0.52
var pitch_inertia := 1000.0
var roll_inertia := 500.0
var initialized := false

func configure(vehicle: Dictionary, ground: Array) -> void:
	var tune: Dictionary=vehicle.get("suspension",{})
	unsprung=float(vehicle.wheel_mass_kg);mass=float(vehicle.mass_kg)-4*unsprung
	radius=float(vehicle.wheel_radius_m);cg=float(vehicle.cg_height_m)
	# ASSUMPTION: provisional wheel rates; config records provenance.
	spring=float(tune.get("spring_npm",vehicle.get("spring_npm",32000)))
	damper=float(tune.get("damper_nspm",vehicle.get("damper_nspm",3200)))
	tyre_spring=float(tune.get("tyre_spring_npm",180000));tyre_damper=float(tune.get("tyre_damper_nspm",450))
	antiroll=float(tune.get("antiroll_npm",10000));ride_height=float(tune.get("ride_height_m",0.55))
	var wb: float=vehicle.wheelbase_m;var width: float=vehicle.track_m;var fraction: float=vehicle.front_fraction
	pitch_inertia=mass*wb*wb*0.26;roll_inertia=mass*width*width*0.32
	height=ride_height+float(ground[0]);speed=0;pitch=0;roll=0;pitch_rate=0;roll_rate=0;hubs.clear()
	for i in 4:
		var f := fraction if i<2 else 1-fraction
		var normal := (mass*f*0.5+unsprung)*9.81
		var hub_y := float(ground[i])+radius-normal/tyre_spring
		hubs.append({"y":hub_y,"velocity":0.0,"x":(-1.0 if i%2==0 else 1.0)*width*0.5,
			"z":wb*(1-fraction) if i<2 else -wb*fraction,"rest":height-hub_y+mass*f*9.81/(2*spring),
			"normal":normal,"spring_force":mass*f*9.81*0.5,"compression":mass*f*9.81/(2*spring)})
	initialized=true

func tick(dt: float, ground: Array, contacts: Array, longitudinal: float, lateral: float, tuning: float=0) -> void:
	var forces: Array[float]=[]
	var k := spring*(1+tuning*0.15)
	var c := damper*(1+tuning*0.10)
	for i in 4:
		var h: Dictionary=hubs[i]
		var attachment := height+pitch*float(h.z)+roll*float(h.x)
		var attach_speed := speed+pitch_rate*float(h.z)+roll_rate*float(h.x)
		var compression := float(h.rest)-attachment+float(h.y)
		var relative_speed := attach_speed-float(h.velocity)
		var force := k*compression-c*relative_speed
		# Progressive bump/rebound stops, retaining force reaction on the wheel.
		force+=maxf(0,compression-0.18)*180000-minf(0,compression+0.10)*-180000
		h.compression=compression;forces.append(force)
	for axle in [0,2]:
		var difference := float(hubs[axle].compression)-float(hubs[axle+1].compression)
		forces[axle]+=antiroll*difference;forces[axle+1]-=antiroll*difference
	var body_force := -mass*9.81
	var pitch_torque := mass*longitudinal*cg
	var roll_torque := mass*lateral*cg
	for i in 4:
		var h: Dictionary=hubs[i]
		var penetration := float(ground[i])+radius-float(h.y)
		# Contact cannot pull the wheel down; zero compression means airborne.
		var normal := maxf(0,tyre_spring*penetration-tyre_damper*float(h.velocity)) if penetration>0 and contacts[i] else 0.0
		h.normal=normal;h.spring_force=forces[i]
		h.velocity+=(normal-forces[i]-unsprung*9.81)/unsprung*dt
		h.y+=float(h.velocity)*dt
		body_force+=forces[i];pitch_torque+=float(h.z)*forces[i];roll_torque+=float(h.x)*forces[i]
	speed+=body_force/mass*dt;height+=speed*dt
	pitch_rate+=pitch_torque/pitch_inertia*dt;pitch+=pitch_rate*dt
	roll_rate+=roll_torque/roll_inertia*dt;roll+=roll_rate*dt
