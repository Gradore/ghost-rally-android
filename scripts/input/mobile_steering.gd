extends RefCounted
var value := 0.0
var velocity := 0.0
func reset() -> void:value=0;velocity=0
func step(target: float,speed: float,dt: float) -> float:
	# Critically damped response with bounded slew, finite and continuous on direction changes.
	target=clampf(target,-1,1)
	var omega := 18.0 if absf(target)>absf(value) else 23.0
	var decay := exp(-omega*dt);var error := value-target;var temp := (velocity+omega*error)*dt
	value=target+(error+temp)*decay;velocity=(velocity-omega*temp)*decay
	value=clampf(value,-1,1)
	return value*lerpf(1.0,0.65,clampf(speed/55.0,0,1))
