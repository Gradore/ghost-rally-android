extends Control
class_name RaceMinimap

var track_world: TrackWorld
var progress := 0.0
var player_position := Vector3.ZERO

func _ready() -> void:
	clip_contents=true
	mouse_filter=Control.MOUSE_FILTER_IGNORE

func _point(world_position: Vector3, center: Vector3, heading: float) -> Vector2:
	var delta := Vector2(world_position.x-center.x,world_position.z-center.z)
	var forward := Vector2(-sin(heading),-cos(heading))
	var right := Vector2(cos(heading),-sin(heading))
	return Vector2(size.x*0.5+delta.dot(right)*0.23,size.y*0.72-delta.dot(forward)*0.23)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.03,0.07,0.08,0.28),true)
	if not is_instance_valid(track_world): return
	var center := track_world.center_at(progress)
	var heading := track_world.heading_at(progress)
	var points := PackedVector2Array()
	var start := maxi(0,int(progress)-220)
	var finish := mini(int(track_world.track.length),int(progress)+550)
	for p in range(start,finish,10):
		points.append(_point(track_world.center_at(float(p)),center,heading))
	points.append(_point(track_world.center_at(float(finish)),center,heading))
	if points.size()>1:
		draw_polyline(points,Color("3b5355"),9.0,true)
		draw_polyline(points,Color("d9dfc9"),4.0,true)
	var marker := _point(player_position,center,heading)
	draw_circle(marker,9.0,Color("152a31"))
	draw_circle(marker,5.0,Color("f6c64e"))
	draw_line(marker,marker+Vector2(0,-13),Color("f6c64e"),3.0,true)
