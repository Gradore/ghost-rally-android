extends Control
# North-up overview of the very same centerline used by the race.
var world: TrackWorld
var low := Vector2.ZERO
var high := Vector2.ONE
func project(p: Vector2) -> Vector2:
	var scale_factor := minf((size.x-30.0)/(high.x-low.x),(size.y-30.0)/(high.y-low.y))
	return size*0.5+(p-(low+high)*0.5)*scale_factor
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	clip_contents=true
	low=Vector2(INF,INF); high=Vector2(-INF,-INF)
	for p in world.route_points:
		var north_up: Vector2=p.rotated(-world.metric_rotation)
		low=low.min(north_up);high=high.max(north_up)
	queue_redraw()
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("12242b"))
	if not is_instance_valid(world):return
	var file := FileAccess.open("res://assets/data/map_features.json",FileAccess.READ)
	var features: Array=JSON.parse_string(file.get_as_text()) if file else []
	for f in features:
		if f.state_code!=world.track.state_code:continue
		for polygon in f.water:
			var points := PackedVector2Array()
			for ll in polygon:
				var p: Vector3=world.geo_to_world(float(ll[0]),float(ll[1]))
				points.append(project(Vector2(p.x,p.z).rotated(-world.metric_rotation)))
			if points.size()>2:draw_colored_polygon(points,Color("285b75"))
	var route := PackedVector2Array()
	for p in world.route_points:route.append(project(p.rotated(-world.metric_rotation)))
	draw_polyline(route,Color("f5ce74"),3.0,true)
	draw_circle(route[0],6.0,Color("6ef0b2"))
	draw_circle(route[-1],3.0,Color("f06d55"))
	draw_string(ThemeDB.fallback_font,Vector2(size.x-24,20),"N",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color.WHITE)
