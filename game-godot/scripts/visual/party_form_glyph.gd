extends Node2D
## Original code-drawn temporary form identifier. Cosmic backdrop is presentation
## only; this is not a final authored kaiju model or completed form animation.
var fighter
var item:=""
var form:=""
func configure(actor,id:String,state_id:String) -> void:
	fighter=actor;item=id;form=state_id;z_index=-1;queue_redraw()
func _draw() -> void:
	if fighter==null:return
	var options=fighter.get_node_or_null("/root/StoryDialogue")
	var reduced:bool=options!=null and bool(options.settings.get("reduced_flash",false))
	var center:=Vector2(0,-32)
	if item=="prism_heart":
		for i in range(7):
			var angle:float=float(i)*TAU/7.0
			var direction:=Vector2.from_angle(angle)
			draw_line(center+direction*38,center+direction*46,Color.from_hsv(float(i)/7,.55,.85,.65),2,true)
	else:
		var color:=Color(.9,.94,1,.75) if form.begins_with("WHITE") or form=="RADIANT_CONDUCTOR" else Color(.42,.28,.64,.85)
		draw_arc(center,43,.3,TAU-.3,32,color,2,true)
		draw_line(center+Vector2(-16,-46),center+Vector2(16,-46),color,2,true)
	if form.ends_with("TRUE_ASPECT"):
		var radius:=100.0
		var cosmic:=Color(.33,.24,.48,.22) if fighter.fighter_id=="yin" else Color(.95,.85,.43,.22)
		# Open, static scale cues preserve the visible vulnerable core.
		draw_arc(center,radius,PI,TAU,40,cosmic,3 if not reduced else 1,true)
		for i in range(3):
			var x:float=(float(i)-1)*90
			draw_line(center+Vector2(x,-60),center+Vector2(x,-110),cosmic,2,true)
