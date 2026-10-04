extends Control
class_name GermanyMap

signal selected(index: int)

const GEO_SCALE := 59.0
const COLORS := [Color("315b5a"),Color("346466"),Color("3c5a60"),Color("315652"),Color("42676a"),Color("3c5e5b"),Color("4d6763"),Color("315b67")]

var states: Array = []
var routes: Array = []
var map_features: Array = []
var track_codes: Array = []
var zoom := 1.0:
	set(value):
		zoom = value
		queue_redraw()
var center_geo := Vector2(10.45,51.13):
	set(value):
		center_geo = value
		queue_redraw()
var highlighted := -1
var stage := 0
var pending_tween: Tween

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	var f := FileAccess.open("res://assets/data/states.json",FileAccess.READ)
	if f: states = JSON.parse_string(f.get_as_text())
	var r := FileAccess.open("res://assets/data/routes.json",FileAccess.READ)
	if r: routes = JSON.parse_string(r.get_as_text())
	var m := FileAccess.open("res://assets/data/map_features.json",FileAccess.READ)
	if m: map_features = JSON.parse_string(m.get_as_text())
	for route in routes: track_codes.append(route.state_code)
	queue_redraw()

func _geo_to_px(geo: Vector2) -> Vector2:
	return size*0.5 + Vector2((geo.x-center_geo.x)*GEO_SCALE*zoom,-(geo.y-center_geo.y)*GEO_SCALE*zoom)

func _px_to_geo(px: Vector2) -> Vector2:
	return center_geo + Vector2((px.x-size.x*0.5)/(GEO_SCALE*zoom),-(px.y-size.y*0.5)/(GEO_SCALE*zoom))

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("0b242b"))
	for yy in range(0,int(size.y),45): draw_line(Vector2(0,yy),Vector2(size.x,yy),Color(0.48,0.72,0.71,0.075),1.0)
	for xx in range(0,int(size.x),45): draw_line(Vector2(xx,0),Vector2(xx,size.y),Color(0.48,0.72,0.71,0.075),1.0)
	for i in states.size():
		var st: Dictionary = states[i]
		for ring in st.polygons:
			var poly := PackedVector2Array()
			for coordinate in ring: poly.append(_geo_to_px(Vector2(float(coordinate[0]),float(coordinate[1]))))
			if poly.size()<3: continue
			var color: Color = COLORS[i%COLORS.size()]
			if i==highlighted: color=Color("315d62") if stage==2 else (Color("d8ae55") if stage==1 else Color("608d81"))
			draw_colored_polygon(poly,color)
			var outline := poly.duplicate(); outline.append(poly[0])
			draw_polyline(outline,Color("a4d0bd") if i==highlighted else Color("779e98"),2.5 if i==highlighted else 1.1,true)
	if stage==2 and highlighted>=0:
		var code: String = states[highlighted].code
		for feature in map_features:
			if feature.state_code!=code: continue
			if zoom<18.0: continue
			for polygon in feature.water:
				var shape := PackedVector2Array()
				for ll in polygon: shape.append(_geo_to_px(Vector2(float(ll[1]),float(ll[0]))))
				if shape.size()>2 and not Geometry2D.triangulate_polygon(shape).is_empty(): draw_colored_polygon(shape,Color("1d6070"))
			for building in feature.buildings:
				var shape := PackedVector2Array()
				for ll in building.p: shape.append(_geo_to_px(Vector2(float(ll[1]),float(ll[0]))))
				if shape.size()>2 and not Geometry2D.triangulate_polygon(shape).is_empty(): draw_colored_polygon(shape,Color("7f9a93"))
			for line_data in feature.roads:
				var line := PackedVector2Array()
				for ll in line_data.p: line.append(_geo_to_px(Vector2(float(ll[1]),float(ll[0]))))
				if line.size()>1:
					var kind: String=line_data.k
					var width: float=6.5 if kind=="major" else (4.0 if kind=="main" else (2.4 if kind=="street" else 1.4))
					draw_polyline(line,Color("aab8a6") if kind=="major" else Color("79958a"),width,true)
		for route in routes:
			if route.state_code!=code: continue
			var line := PackedVector2Array()
			for ll in route.coordinates: line.append(_geo_to_px(Vector2(float(ll[1]),float(ll[0]))))
			if line.size()>1:
				draw_polyline(line,Color("183641"),13.0,true)
				draw_polyline(line,Color("f6c64f"),6.0,true)
				draw_circle(line[0],8.0,Color("72d9c9"))
				draw_circle(line[-1],8.0,Color("ff8b66"))
				draw_string(get_theme_default_font(),line[-1]+Vector2(13,-9),"ZIEL",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("ffe5af"))
		draw_string(get_theme_default_font(),Vector2(15,size.y-15),"KARTENDATEN  © OPENSTREETMAP",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("d1e6d6"))
	for route in routes:
		if stage==2: continue
		var index := -1
		for i in states.size():
			if states[i].code==route.state_code: index=i; break
		if index<0: continue
		var ll: Array=route.coordinates[int(route.coordinates.size()/2)]
		var p := _geo_to_px(Vector2(float(ll[1]),float(ll[0])))
		if p.x<0 or p.y<0 or p.x>size.x or p.y>size.y: continue
		draw_circle(p,5.5 if index==highlighted else 3.5,Color("ffdc77") if index==highlighted else Color("cce8db"))

func _gui_input(event: InputEvent) -> void:
	if stage!=0: return
	var tap := false
	var pos := Vector2.ZERO
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		tap=true; pos=event.position
	if event is InputEventScreenTouch and event.pressed:
		tap=true; pos=event.position
	if not tap: return
	var geo := _px_to_geo(pos)
	for i in states.size():
		for ring in states[i].polygons:
			var poly := PackedVector2Array()
			for coordinate in ring: poly.append(Vector2(float(coordinate[0]),float(coordinate[1])))
			if Geometry2D.is_point_in_polygon(geo,poly):
				choose_code(states[i].code)
				accept_event()
				return

func _bbox_for_state(st: Dictionary) -> Rect2:
	var lo := Vector2(100,100)
	var hi := Vector2(-100,-100)
	for ring in st.polygons:
		for ll in ring:
			var p := Vector2(float(ll[0]),float(ll[1]))
			lo=lo.min(p); hi=hi.max(p)
	return Rect2(lo,hi-lo)

func _bbox_for_route(route: Dictionary) -> Rect2:
	var lo := Vector2(100,100)
	var hi := Vector2(-100,-100)
	for ll in route.coordinates:
		var p := Vector2(float(ll[1]),float(ll[0]))
		lo=lo.min(p); hi=hi.max(p)
	return Rect2(lo,hi-lo)

func _zoom_for(box: Rect2, padding: float) -> float:
	return minf(size.x/(maxf(box.size.x,0.015)*GEO_SCALE*padding),size.y/(maxf(box.size.y,0.015)*GEO_SCALE*padding))

func choose_code(code: String) -> void:
	var i := -1
	for j in states.size():
		if states[j].code==code: i=j; break
	if i<0: return
	if pending_tween: pending_tween.kill()
	stage=1; highlighted=i; queue_redraw()
	var box := _bbox_for_state(states[i])
	pending_tween=create_tween()
	pending_tween.set_parallel(true)
	pending_tween.tween_property(self,"center_geo",box.get_center(),0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	pending_tween.tween_property(self,"zoom",_zoom_for(box,1.32),0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await pending_tween.finished
	stage=2; queue_redraw()
	var route: Dictionary={}
	for r in routes:
		if r.state_code==code: route=r; break
	if route.is_empty(): return
	box=_bbox_for_route(route)
	pending_tween=create_tween()
	pending_tween.set_parallel(true)
	pending_tween.tween_property(self,"center_geo",box.get_center(),0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	pending_tween.tween_property(self,"zoom",minf(_zoom_for(box,1.5),1200),0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await pending_tween.finished
	selected.emit(track_codes.find(code))

func reset_view() -> void:
	if pending_tween: pending_tween.kill()
	highlighted=-1
	stage=0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self,"center_geo",Vector2(10.45,51.13),0.55)
	tween.tween_property(self,"zoom",1.0,0.55)
	queue_redraw()
