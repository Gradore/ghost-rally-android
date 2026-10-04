extends RefCounted
class_name RallyTyreModel

# Constant-coefficient Magic Formula. Parameters are fitted assumptions, not RBR data.
static func magic(slip: float, normal_load: float, coefficients: Array) -> float:
	var bx := float(coefficients[0])*slip
	return maxf(0.0,normal_load)*float(coefficients[2])*sin(float(coefficients[1])*atan(bx-float(coefficients[3])*(bx-atan(bx))))

static func combined(longitudinal: float, lateral: float, capacity: float) -> Vector2:
	var force := Vector2(longitudinal,lateral)
	if capacity<=0.0:return Vector2.ZERO
	return force*minf(1.0,capacity/maxf(force.length(),0.001))

static func thermal_grip(temperature_k: float, pressure_pa: float) -> float:
	# ASSUMPTION: broad optimum around 333 K and 200 kPa; calibrate against tyre data.
	return clampf(1.0-pow((temperature_k-333.0)/150.0,2)*0.25-absf(pressure_pa-200000.0)/800000.0,0.60,1.0)
