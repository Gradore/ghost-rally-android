extends Control
var game: Node
func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
func _process(_delta: float) -> void:queue_redraw()
func _draw() -> void:
	var c := size*0.5;var radius := minf(size.x,size.y)*0.40
	draw_circle(c,radius+5,Color(0.01,0.04,0.05,0.25))
	draw_arc(c,radius,0,TAU,64,Color(0.90,0.96,0.95,0.85),3,true)
	var angle: float=game.steer*1.15 if is_instance_valid(game) else 0.0
	for a in [0.0,PI,PI*0.5]:
		draw_line(c,c+Vector2(cos(a+angle),sin(a+angle))*radius,Color(0.90,0.96,0.95,0.80),3,true)
	draw_circle(c,12,Color("e7bc56"))
