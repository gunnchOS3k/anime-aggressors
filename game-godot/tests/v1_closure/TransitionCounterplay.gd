extends "res://tests/v1_closure/SpectralCapture.gd"
## One bounded initiative change, not an AI change. Public player approaches,
## waits/defends, then attacks; CPU remains active under existing battle rules.
func _probe_inputs(frame:int,p:Node,dx:float)->Array:
	if probe!="transition-counterplay":return super._probe_inputs(frame,p,dx)
	var actions:Array=[]
	if absf(dx)>42:actions.append("right" if dx>0 else "left")
	if frame<360:return actions
	if frame<540:
		if frame%90<45:actions.append("shield")
		return actions
	if absf(dx)<65 and p.state_machine.can_attack() and frame%12==0:actions.append("attack")
	return actions
