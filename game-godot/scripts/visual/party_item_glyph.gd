extends Node2D
var item_id:="prism_heart"
var variant:="BLACK"
func _draw() -> void:
	if item_id=="prism_heart":
		for i in range(7):
			var a:float=float(i)*TAU/7.0-PI/2
			var b:float=float(i+1)*TAU/7.0-PI/2
			var color:=Color.from_hsv(float(i)/7,.65,.9,.9)
			draw_colored_polygon(PackedVector2Array([Vector2.ZERO,Vector2.from_angle(a)*13,Vector2.from_angle(b)*13]),color)
		draw_arc(Vector2.ZERO,16,0,TAU,28,Color(.9,.96,1,.8),1.5,true)
	else:
		var color:=Color(.85,.93,1,.95) if variant=="WHITE" else Color(.5,.35,.8,.95)
		draw_arc(Vector2.ZERO,14,0,TAU,24,color,2,true)
		draw_line(Vector2(-7,-8),Vector2(7,8),color,3,true)
		draw_line(Vector2(-7,8),Vector2(7,-8),color,3,true)
