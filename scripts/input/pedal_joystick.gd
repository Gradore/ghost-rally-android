extends Control
var game: Node
func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
func _process(_delta: float) -> void:queue_redraw()
func _draw() -> void:
	var center := size*Vector2(0.5,0.48);var radius := 69.0
	draw_circle(center,radius+8,Color(0.015,0.035,0.04,0.65))
	draw_arc(center,radius,0,TAU,64,Color(0.8,0.91,0.9,0.75),2,true)
	draw_line(center-Vector2(0,55),center+Vector2(0,55),Color(0.8,0.91,0.9,0.35),2,true)
	var amount: float=game.throttle-game.brake if is_instance_valid(game) else 0.0
	draw_circle(center+Vector2(0,-amount*52),21,Color("f4c64f") if amount>=0 else Color("ec9486"))
	draw_string(game.font_bold,Vector2(92,16),"GAS ↑",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("f4c64f"))
	draw_string(game.font_bold,Vector2(76,180),"BREMSE ↓",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("ec9486"))
