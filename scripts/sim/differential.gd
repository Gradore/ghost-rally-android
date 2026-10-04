extends RefCounted
class_name RallyDifferential

static func split(torque: float, omega_left: float, omega_right: float, cfg: Dictionary) -> Vector2:
	if cfg.get("type","lsd")=="open":return Vector2.ONE*torque*0.5
	# ASSUMPTION: damped Salisbury approximation, not clutch-pack geometry.
	var lock := float(cfg.get("power_lock",0.35)) if torque>=0 else float(cfg.get("coast_lock",0.15))
	var limit := float(cfg.get("preload_nm",35.0))+absf(torque)*lock*0.5
	var transfer := clampf((omega_left-omega_right)*float(cfg.get("damping",8.0)),-limit,limit)
	return Vector2(torque*0.5-transfer,torque*0.5+transfer)
